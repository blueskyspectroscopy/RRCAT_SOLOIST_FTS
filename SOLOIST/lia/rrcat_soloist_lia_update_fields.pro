;+
; NAME:
; RRCAT_SOLOIST_LIA_UPDATE_FIELDS
;
; PURPOSE:
; This procedure updates the LIA fields in the GUI.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
;
; INPUTS:
; info: The info structure
;
; KEYWORDS:
;
; MODIFICATION HISTORY:
; 27 August 2019 (TRF): Added debug keyword to replicate the string
;                       combining from RRCAT_STEPPER_PARSE_STRING()
;                       to test whether this causes a slowdown.
; 28 August 2019 (TRF): Reverted back to original version as the casue of the 
;                       slowdown has been discovered.
;-
PRO RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info

  lia_settings = info.lia_settings
  result = info.lia->getFreq(error = err)
  WIDGET_CONTROL, info.lia_freq_field, SET_VALUE=STRTRIM(result, 2)
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Frequency: ' + result
  lia_settings.freq = result

  result = info.lia->getTau(error = err)
  strResult = rrcat_lia_translate_values(result, /TAU)
  WIDGET_CONTROL, info.lia_tau_field, SET_VALUE=strResult
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Time Constant: ' + result + ' ' + strResult
  lia_settings.tau = result

  result = info.lia->getSens(error = err)
  strResult = rrcat_lia_translate_values(result, /SENS)
  WIDGET_CONTROL, info.lia_sens_field, SET_VALUE=strResult
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Sensitivity: ' + result + ' ' + strResult
  lia_settings.sens = result

  result = info.lia->getReserve(error = err)
  strResult = rrcat_lia_translate_values(result, /RESERVE)
  WIDGET_CONTROL, info.lia_reserve_field, SET_VALUE=strResult
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Reserve: ' + result + ' ' + strResult
  lia_settings.reserve = result

  result = info.lia->getFilter(error = err)
  strResult = rrcat_lia_translate_values(result, /FILT)
  WIDGET_CONTROL, info.lia_filter_field, SET_VALUE=strResult
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Filter: ' + result + ' ' + strResult
  lia_settings.filter = result

  result = info.lia->getPhase(error = err)
  WIDGET_CONTROL, info.lia_phase_field, SET_VALUE=STRTRIM(result, 2)
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Phase: ' + result
  lia_settings.phase = result

  result = info.lia->getCoupling()
  strResult = rrcat_lia_translate_values(result, /COUP)
  WIDGET_CONTROL, info.lia_coupling_field, SET_VALUE=strResult
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Coupling: ' + result + ' ' + strResult
  lia_settings.coupling = result

  result = info.lia->getGrounding(error = err)
  strResult = rrcat_lia_translate_values(result, /GND)
  WIDGET_CONTROL, info.lia_ground_field, SET_VALUE=strResult
  IF info.debug THEN SOLOIST_FTS_MESSAGE, info, 'Grounding: ' + result + ' ' + strResult
  lia_settings.grounding = result

  info.lia_settings = lia_settings

END