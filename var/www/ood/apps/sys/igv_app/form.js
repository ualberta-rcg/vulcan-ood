'use strict';

// SourceURL
//# sourceURL=form.js

// SETUP ----------------------------------------------------------------------------------------------------------------
const gpuDataField = document.getElementById('batch_connect_session_context_gpudata');
const gpuData = JSON.parse(gpuDataField.value);

const gpuMappings = gpuData.gpu_name_mappings || {};
const gpuMaxCounts = gpuData.gpu_max_counts || {};

const memoryDataField = document.getElementById('batch_connect_session_context_memorydata');
const cpuDataField = document.getElementById('batch_connect_session_context_cpunum');

const maxMemoryGB = parseInt(memoryDataField.value, 10) || 64;
const maxCpus = parseInt(cpuDataField.value, 10) || 32;

const minCpuField = document.getElementById('batch_connect_session_context_mincpu');
const minRamField = document.getElementById('batch_connect_session_context_minram');

const minCpus = parseInt(minCpuField?.value || '2', 10);
const minRam = parseInt(minRamField?.value || '4', 10);

function isFractionalGpuId(id) {
  return typeof id === 'string' && /\.[0-9]+$/.test(id);
}

function baseGpuTypeFromId(id) {
  if (typeof id !== 'string') return id;
  return id.replace(/\.[0-9]+$/, '');
}

function currentGpuCount() {
  const v = parseInt($('#batch_connect_session_context_gpu_count').val(), 10);
  return Number.isFinite(v) && v > 0 ? v : 1;
}

// -- GPU Type Dropdown: hide fractional options when requesting multiple full GPUs (count > 1) -------------------------
function updateGpuTypeDropdown() {
  const gpuSelect = $('#batch_connect_session_context_gpu_type');
  const gpuCheckbox = $('#batch_connect_session_context_gpu_checkbox');

  gpuSelect.empty();

  if (!gpuCheckbox.is(':checked')) {
    gpuSelect.append(new Option('none', 'none'));
    return;
  }

  const cnt = currentGpuCount();
  const keys = Object.keys(gpuMappings);
  if (keys.length === 0) {
    gpuSelect.append(new Option('(no GPUs configured)', 'none'));
    return;
  }

  keys.forEach((gpuId) => {
    if (cnt > 1 && isFractionalGpuId(gpuId)) return;
    gpuSelect.append(new Option(gpuMappings[gpuId], gpuId));
  });

  if (gpuSelect.find('option').length === 0) {
    gpuSelect.append(new Option('none', 'none'));
  }
}

// -- GPU count min/max; fractional types allow count up to gpu_max_counts (often > 1) -----------------------------------
function updateGpuCountMax() {
  const selectedGpu = $('#batch_connect_session_context_gpu_type').val();
  const gpuCountField = $('#batch_connect_session_context_gpu_count');

  if (!selectedGpu || selectedGpu === 'none') {
    gpuCountField.attr('max', 1);
    gpuCountField.attr('min', 1);
    gpuCountField.parent().hide();
    return;
  }

  gpuCountField.parent().show();
  const maxC = gpuMaxCounts[selectedGpu];
  const maxVal = maxC !== undefined && maxC !== null ? parseInt(maxC, 10) : 1;
  const safeMax = Number.isFinite(maxVal) && maxVal > 0 ? maxVal : 1;
  gpuCountField.attr('max', safeMax);
  gpuCountField.attr('min', 1);

  let cur = parseInt(gpuCountField.val(), 10);
  if (!Number.isFinite(cur) || cur < 1) cur = 1;
  if (cur > safeMax) gpuCountField.val(String(safeMax));
}

function onGpuTypeChanged() {
  const sel = $('#batch_connect_session_context_gpu_type').val();
  const gpuCountField = $('#batch_connect_session_context_gpu_count');
  if (isFractionalGpuId(sel)) {
    const c = currentGpuCount();
    if (c > 1) gpuCountField.val('1');
  }
  updateGpuCountMax();
}

function onGpuCountChanged() {
  const sel = $('#batch_connect_session_context_gpu_type').val();
  const cnt = currentGpuCount();
  if (cnt > 1 && isFractionalGpuId(sel)) {
    const base = baseGpuTypeFromId(sel);
    if (base && gpuMappings[base] !== undefined) {
      $('#batch_connect_session_context_gpu_type').val(base);
    }
  }
  updateGpuTypeDropdown();
  const selAfter = $('#batch_connect_session_context_gpu_type').val();
  if (selAfter === 'none' || !selAfter) {
    const first = $('#batch_connect_session_context_gpu_type option').filter(function () {
      return $(this).val() && $(this).val() !== 'none';
    }).first();
    if (first.length) $('#batch_connect_session_context_gpu_type').val(first.val());
  }
  updateGpuCountMax();
}

// -- GPU Fields Toggle (checkbox) -------------------------------------------------------------
function toggleGpuFields() {
  const gpuCheckbox = $('#batch_connect_session_context_gpu_checkbox');
  const gpuType = $('#batch_connect_session_context_gpu_type');
  const gpuCount = $('#batch_connect_session_context_gpu_count');

  const isHidden = gpuCheckbox.attr('type') === 'hidden';
  let showGpu;

  if (isHidden) {
    showGpu = gpuCheckbox.val() === '1';
  } else {
    showGpu = gpuCheckbox.is(':checked');
  }

  if (showGpu) {
    updateGpuTypeDropdown();
    updateGpuCountMax();
    gpuType.parent().show();
    gpuCount.parent().show();
  } else {
    gpuType.empty();
    gpuType.parent().hide();
    gpuCount.val('1');
    gpuCount.parent().hide();
  }
}

// -- Additional Environment Toggle (checkbox) --------------------------------------------------
function toggleAdditionalEnv() {
  const addEnvCheckbox = $('#batch_connect_session_context_add_env_checkbox');
  const additionalEnv = $('#batch_connect_session_context_additional_environment');

  const showAddEnv = addEnvCheckbox.is(':checked');
  additionalEnv.parent().toggle(showAddEnv);

  if (!showAddEnv) {
    additionalEnv.val('');
  }
}

function toggleMemtask() {
  const memtaskCheckbox = $('#batch_connect_session_context_memtask_checkbox');
  const memtaskField = $('#batch_connect_session_context_memtask');

  const isHidden = memtaskCheckbox.attr('type') === 'hidden';
  let checked;

  if (isHidden) {
    checked = memtaskCheckbox.val() === '1';
  } else {
    checked = memtaskCheckbox.is(':checked');
  }

  if (checked) {
    memtaskCheckbox.val('1');
    memtaskField.parent().show();

    memtaskField.find('option').each(function () {
      const memVal = parseInt($(this).val(), 10);
      if (memVal > maxMemoryGB || memVal < minRam) {
        $(this).hide();
      } else {
        $(this).show();
      }
    });

    const currentVal = parseInt(memtaskField.val(), 10);
    if (currentVal < minRam) {
      memtaskField.val(String(minRam));
    }
  } else {
    memtaskCheckbox.val('0');
    memtaskField.val('2');
    memtaskField.parent().hide();
  }
}

// INIT ------------------------------------------------------------------------------------------------------------
$(document).ready(function () {
  toggleGpuFields();
  toggleAdditionalEnv();
  toggleMemtask();
  onGpuCountChanged();

  $('#batch_connect_session_context_gpu_checkbox').change(toggleGpuFields);
  $('#batch_connect_session_context_gpu_type').change(onGpuTypeChanged);
  $('#batch_connect_session_context_gpu_count').on('change input', onGpuCountChanged);
  $('#batch_connect_session_context_add_env_checkbox').change(toggleAdditionalEnv);
  $('#batch_connect_session_context_memtask_checkbox').change(toggleMemtask);
  $('#batch_connect_session_context_num_cores').attr('max', maxCpus);
  $('#batch_connect_session_context_num_cores').attr('min', minCpus);

  const currentCores = parseInt($('#batch_connect_session_context_num_cores').val(), 10);
  if (currentCores < minCpus) {
    $('#batch_connect_session_context_num_cores').val(minCpus);
  }
});
