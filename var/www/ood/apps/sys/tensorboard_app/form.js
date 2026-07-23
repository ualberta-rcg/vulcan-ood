'use strict';

// SourceURL
//# sourceURL=form.js

// SETUP ----------------------------------------------------------------------------------------------------------------
const memoryDataField = document.getElementById('batch_connect_session_context_memorydata');
const cpuDataField = document.getElementById('batch_connect_session_context_cpunum');

const maxMemoryGB = parseInt(memoryDataField.value, 10) || 64;
const maxCpus = parseInt(cpuDataField.value, 10) || 32;

const minCpuField = document.getElementById('batch_connect_session_context_mincpu');
const minRamField = document.getElementById('batch_connect_session_context_minram');

const minCpus = parseInt(minCpuField?.value || '2', 10);
const minRam = parseInt(minRamField?.value || '4', 10);

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
    memtaskField.val(String(minRam));
    memtaskField.parent().hide();
  }
}

// INIT ------------------------------------------------------------------------------------------------------------
$(document).ready(function () {
  toggleAdditionalEnv();
  toggleMemtask();

  $('#batch_connect_session_context_add_env_checkbox').change(toggleAdditionalEnv);
  $('#batch_connect_session_context_memtask_checkbox').change(toggleMemtask);

  const numCoresField = $('#batch_connect_session_context_num_cores');
  numCoresField.attr('max', maxCpus);
  numCoresField.attr('min', minCpus);

  const currentCores = parseInt(numCoresField.val(), 10);
  if (currentCores < minCpus) {
    numCoresField.val(minCpus);
  }

  const memtaskField = $('#batch_connect_session_context_memtask');
  if (memtaskField.parent().is(':visible')) {
    const mv = parseInt(memtaskField.val(), 10);
    memtaskField.val(String(mv < minRam ? minRam : mv));
  }
});
