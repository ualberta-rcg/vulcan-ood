'use strict';

// SourceURL
//# sourceURL=form.js

// SETUP ----------------------------------------------------------------------------------------------------------------
const gpuDataField = document.getElementById('batch_connect_session_context_gpudata');
const gpuData = JSON.parse(gpuDataField.value);

const memoryDataField = document.getElementById('batch_connect_session_context_memorydata');
const cpuDataField = document.getElementById('batch_connect_session_context_cpunum');

const maxMemoryGB = parseInt(memoryDataField.value) || 64;
const maxCpus = parseInt(cpuDataField.value) || 32;

const minCpuField = document.getElementById('batch_connect_session_context_mincpu');
const minRamField = document.getElementById('batch_connect_session_context_minram');

const minCpus = parseInt(minCpuField?.value || "2", 10);
const minRam = parseInt(minRamField?.value || "4", 10);

// -- GPU Type Dropdown Handling --------------------------------------------------------------
function updateGpuTypeDropdown() {
  const gpuSelect = $('#batch_connect_session_context_gpu_type');
  const gpuCheckbox = $('#batch_connect_session_context_gpu_checkbox');

  gpuSelect.empty();  // Always clear it first

  if (gpuCheckbox.is(':checked')) {
    Object.keys(gpuData.gpu_name_mappings).forEach(gpuId => {
      gpuSelect.append(new Option(gpuData.gpu_name_mappings[gpuId], gpuId));
    });
  } else {
    // When not checked, dropdown stays empty
    gpuSelect.append(new Option('none', 'none'));  // Or no option at all, depends on your design
  }
}


// -- GPU Count Max Handling --------------------------------------------------------------------

function updateGpuCountMax() {
  const selectedGpu = $('#batch_connect_session_context_gpu_type').val();
  const gpuCountField = $('#batch_connect_session_context_gpu_count');

  if (selectedGpu && gpuData.gpu_max_counts[selectedGpu]) {
    gpuCountField.attr('max', gpuData.gpu_max_counts[selectedGpu]);
  } else {
    gpuCountField.attr('max', 1);
  }

  if (selectedGpu === "none") {
    gpuCountField.parent().hide();
  } else {
    gpuCountField.parent().show();
  }
}

// -- GPU Fields Toggle (checkbox) -------------------------------------------------------------
function toggleGpuFields() {
  const gpuCheckbox = $('#batch_connect_session_context_gpu_checkbox');
  const gpuType = $('#batch_connect_session_context_gpu_type');
  const gpuCount = $('#batch_connect_session_context_gpu_count');

  // Detect if the field is a visible checkbox or a hidden input
  const isHidden = gpuCheckbox.attr('type') === 'hidden';
  let showGpu;

  if (isHidden) {
    showGpu = gpuCheckbox.val() === "1";
  } else {
    showGpu = gpuCheckbox.is(':checked');
  }

  console.log('--- toggleGpuFields() called ---');
  console.log('gpuCheckbox checked/hidden?:', showGpu);
  console.log('Current gpuData:', gpuData);
  console.log('Available GPU IDs:', Object.keys(gpuData.gpu_name_mappings));

  if (showGpu) {
    console.log('GPU checkbox checked or hidden, populating GPU dropdown...');
    updateGpuTypeDropdown();   // Populate dropdown
    updateGpuCountMax();
    gpuType.parent().show();
    gpuCount.parent().show();
  } else {
    console.log('GPU checkbox unchecked/hidden off, clearing GPU dropdown...');
    gpuType.empty();  // Clear selection
    gpuType.parent().hide();
    gpuCount.val('1'); // reset
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

  // Check if the field is hidden or a checkbox
  const isHidden = memtaskCheckbox.attr('type') === 'hidden';
  let checked;

  if (isHidden) {
    checked = memtaskCheckbox.val() === "1";
  } else {
    checked = memtaskCheckbox.is(':checked');
  }

  if (checked) {
    memtaskCheckbox.val('1');
    memtaskField.parent().show();

    // Dynamically filter memory options based on min/max
    memtaskField.find('option').each(function () {
      const memVal = parseInt($(this).val());
      if (memVal > maxMemoryGB || memVal < minRam) {
        $(this).hide();
      } else {
        $(this).show();
      }
    });

    // If current selection is below min, set it
    const currentVal = parseInt(memtaskField.val());
    if (currentVal < minRam) {
      memtaskField.val(minRam);
    }

  } else {
    memtaskCheckbox.val('0');
    memtaskField.val('2'); // Reset to default
    memtaskField.parent().hide();
  }
}

// INIT ------------------------------------------------------------------------------------------------------------
$(document).ready(function () {
  console.log('Page loaded, trying to find GPU checkbox...');
  console.log('gpu_checkbox element:', $('#batch_connect_session_context_gpu_checkbox'));

  // Initial state: don't call updateGpuTypeDropdown()
  toggleGpuFields();
  toggleAdditionalEnv();
  toggleMemtask();

  // Checkbox handlers
  $('#batch_connect_session_context_gpu_checkbox').change(toggleGpuFields);
  $('#batch_connect_session_context_gpu_type').change(updateGpuCountMax);
  $('#batch_connect_session_context_add_env_checkbox').change(toggleAdditionalEnv);
  $('#batch_connect_session_context_memtask_checkbox').change(toggleMemtask);
  $('#batch_connect_session_context_num_cores').attr('max', maxCpus);
  $('#batch_connect_session_context_num_cores').attr('min', minCpus);

  // Set value to min if too low
  const currentCores = parseInt($('#batch_connect_session_context_num_cores').val(), 10);
  if (currentCores < minCpus) {
    $('#batch_connect_session_context_num_cores').val(minCpus);
  }
});