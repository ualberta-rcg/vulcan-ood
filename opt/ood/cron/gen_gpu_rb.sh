#!/bin/bash
# Generates /etc/ood/config/apps/dashboard/initializers/paice_gpu_info.rb from Slurm Gres=.
# - Parses gpu:type:count and shard counts; comma-safe (no shard corrupting gpu counts).
# - softmig_slices: 0 = full GPU only, 2 = +half (T.2), 4 = +quarter (T.4). Default 4 if unset.
#   Override: env SOFTMIG_SLICES, or /etc/ood/config/softmig_slices (one integer per line).
# - Fractional rows only if shard appears in Gres=; slices_per_gpu = min(S/M) per line where both present.
set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "gen_gpu_rb.sh: must run as root (e.g. sudo $0)" >&2
  exit 1
fi

OUTDIR="/etc/ood/config/apps/dashboard/initializers"
OUTFILE="${OUTDIR}/paice_gpu_info.rb"
SOFTMIG_FILE="/etc/ood/config/softmig_slices"

mkdir -p "$OUTDIR"
mkdir -p "$(dirname "$SOFTMIG_FILE")"

# --- Resolve softmig_slices (env > file > default 4) ---
if [[ -n "${SOFTMIG_SLICES:-}" ]]; then
  SOFTMIG_TIER="$SOFTMIG_SLICES"
elif [[ -r "$SOFTMIG_FILE" ]]; then
  SOFTMIG_TIER="$(grep -v '^[[:space:]]*#' "$SOFTMIG_FILE" | grep -m1 -oE '[0-9]+' || true)"
  [[ -z "$SOFTMIG_TIER" ]] && SOFTMIG_TIER=4
else
  SOFTMIG_TIER=4
fi

case "$SOFTMIG_TIER" in
  0|2|4) ;;
  8) SOFTMIG_TIER=4 ;; # v1: treat 8 as 4 (no T.8 yet)
  *) echo "gen_gpu_rb.sh: invalid softmig_slices '$SOFTMIG_TIER', using 4" >&2; SOFTMIG_TIER=4 ;;
esac

# Collect Gres= values (one per line, may repeat across nodes; uniq patterns)
mapfile -t GRES_LINES < <(scontrol show node 2>/dev/null | grep -oP 'Gres=\K[^ ]+' | sort -u || true)

GRES_HAS_SHARD=0
declare -A GPU_MAX=()
SHARD_MAX=0
MIN_SPG=""  # min slices_per_gpu across qualifying lines (conservative for heterogeneous)

for line in "${GRES_LINES[@]:-}"; do
  [[ -z "$line" ]] && continue

  line_M=0
  line_S=0
  IFS=',' read -ra SEGS <<< "$line"
  for raw in "${SEGS[@]}"; do
    seg="${raw#"${raw%%[![:space:]]*}"}"
    seg="${seg%"${seg##*[![:space:]]}"}"

    if [[ "$seg" =~ ^gpu:([^:]+):([0-9]+) ]]; then
      gtype="${BASH_REMATCH[1]}"
      gc="${BASH_REMATCH[2]}"
      prev="${GPU_MAX[$gtype]:-0}"
      if (( gc > prev )); then
        GPU_MAX["$gtype"]=$gc
      fi
      if (( gc > line_M )); then
        line_M=$gc
      fi
    elif [[ "$seg" =~ ^shard: ]]; then
      GRES_HAS_SHARD=1
      sc=""
      if [[ "$seg" =~ ^shard:([0-9]+)$ ]]; then
        sc="${BASH_REMATCH[1]}"
      elif [[ "$seg" =~ :([0-9]+)$ ]]; then
        sc="${BASH_REMATCH[1]}"
      fi
      if [[ -n "$sc" ]]; then
        if (( sc > SHARD_MAX )); then
          SHARD_MAX=$sc
        fi
        if (( sc > line_S )); then
          line_S=$sc
        fi
      fi
    fi
  done

  if (( line_S > 0 && line_M > 0 )) && (( line_S % line_M == 0 )); then
    spg=$((line_S / line_M))
    if [[ -z "$MIN_SPG" ]] || (( spg < MIN_SPG )); then
      MIN_SPG=$spg
    fi
  fi
done

# If shard and gpu never shared one Gres= line, derive slices_per_gpu from cluster-wide max shard / max gpu count
if [[ -z "${MIN_SPG:-}" ]] && (( SHARD_MAX > 0 )); then
  maxM=0
  for T in "${!GPU_MAX[@]}"; do
    m="${GPU_MAX[$T]}"
    (( m > maxM )) && maxM=$m
  done
  if (( maxM > 0 )) && (( SHARD_MAX % maxM == 0 )); then
    MIN_SPG=$((SHARD_MAX / maxM))
  fi
fi

# Effective fractional tier: no shard in Slurm → no fractional UI rows
EFFECTIVE_TIER=0
if (( GRES_HAS_SHARD == 1 )); then
  EFFECTIVE_TIER=$SOFTMIG_TIER
fi

SLICES_PER_GPU_RUBY="nil"
SHARING_RUBY="false"
if (( GRES_HAS_SHARD == 1 )) && [[ -n "${MIN_SPG:-}" ]] && (( MIN_SPG > 0 )); then
  SLICES_PER_GPU_RUBY="$MIN_SPG"
  SHARING_RUBY="true"
fi

# --- Build ordered type list and max counts in temp files ---
TMP_TYPES="$(mktemp)"
TMP_MAP="$(mktemp)"
TMP_CNT="$(mktemp)"
trap 'rm -f "$TMP_TYPES" "$TMP_MAP" "$TMP_CNT"' EXIT

BASE_TYPES=()
while IFS= read -r k; do
  [[ -n "$k" ]] && BASE_TYPES+=("$k")
done < <(printf '%s\n' "${!GPU_MAX[@]}" | sort)

for T in "${BASE_TYPES[@]:-}"; do
  M="${GPU_MAX[$T]}"
  echo "$T" >>"$TMP_TYPES"
  echo "      \"$T\" => \"NVIDIA ${T^^} (full)\"," >>"$TMP_MAP"
  echo "      \"$T\" => $M," >>"$TMP_CNT"

  if (( EFFECTIVE_TIER >= 2 )) && [[ -n "${MIN_SPG:-}" ]] && (( MIN_SPG >= 2 )); then
    key="${T}.2"
    echo "$key" >>"$TMP_TYPES"
    echo "      \"$key\" => \"NVIDIA ${T^^} (1/2 GPU)\"," >>"$TMP_MAP"
    if (( SHARD_MAX > 0 )) && (( MIN_SPG > 0 )) && (( (SHARD_MAX * 2) % MIN_SPG == 0 )); then
      fmax=$((SHARD_MAX * 2 / MIN_SPG))
    else
      fmax=$((M * MIN_SPG / 2))
      (( fmax < 1 )) && fmax=1
    fi
    echo "      \"$key\" => $fmax," >>"$TMP_CNT"
  fi

  if (( EFFECTIVE_TIER >= 4 )) && [[ -n "${MIN_SPG:-}" ]] && (( MIN_SPG >= 4 )); then
    key="${T}.4"
    echo "$key" >>"$TMP_TYPES"
    echo "      \"$key\" => \"NVIDIA ${T^^} (1/4 GPU)\"," >>"$TMP_MAP"
    if (( SHARD_MAX > 0 )) && (( MIN_SPG > 0 )) && (( (SHARD_MAX * 4) % MIN_SPG == 0 )); then
      fmax=$((SHARD_MAX * 4 / MIN_SPG))
    else
      fmax=$((M * MIN_SPG / 4))
      (( fmax < 1 )) && fmax=1
    fi
    echo "      \"$key\" => $fmax," >>"$TMP_CNT"
  fi
done

{
  echo "# AUTOGENERATED: DO NOT EDIT MANUALLY"
  echo "# softmig_slices=$SOFTMIG_TIER effective_tier=$EFFECTIVE_TIER gres_has_shard=$GRES_HAS_SHARD"
  echo "module CustomGPUInfo"
  echo "  def self.gpu_types"
  echo "    ["
  if [[ -s "$TMP_TYPES" ]]; then
    while IFS= read -r t; do
      echo "      \"${t//\"/\\\"}\","
    done <"$TMP_TYPES"
  fi
  echo "    ]"
  echo "  end"
  echo "  def self.gpu_name_mappings"
  echo "    {"
  if [[ -s "$TMP_MAP" ]]; then
    cat "$TMP_MAP"
  fi
  echo "    }"
  echo "  end"
  echo "  def self.gpu_max_counts"
  echo "    {"
  if [[ -s "$TMP_CNT" ]]; then
    cat "$TMP_CNT"
  fi
  echo "    }"
  echo "  end"
  echo "  def self.gpu_sharing_available"
  echo "    $SHARING_RUBY"
  echo "  end"
  echo "  def self.slices_per_gpu"
  echo "    $SLICES_PER_GPU_RUBY"
  echo "  end"
  echo "end"
} >"$OUTFILE"

chmod 644 "$OUTFILE"
echo "Generated $OUTFILE successfully at $(date) (tier=$EFFECTIVE_TIER shard_max=$SHARD_MAX spg=${MIN_SPG:-na})"
