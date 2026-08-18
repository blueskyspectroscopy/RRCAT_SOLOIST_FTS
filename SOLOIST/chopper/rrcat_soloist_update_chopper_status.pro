;+
; NAME:
; RRCAT_SOLOIST_UPDATE_CHOPPER_STATUS
;
; PURPOSE:
; This procedure updates the GUI chopper status fields.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_UPDATE_CHOPPER_STATUS, info
;
; INPUTS:
; info:  the main info block structure.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 21 2018.
;-
PRO rrcat_soloist_update_chopper_status, info, FIELDS=FIELDS


  ;info.freq_field_chop->set_value,STRTRIM(info.current_chopper_freq, 2)
  IF KEYWORD_SET(FIELDS) THEN BEGIN
    info.freq_field_chop->set_value,STRTRIM(info.current_chopper_freq, 2)
    info.cycle_field_chop->set_value,STRTRIM(info.current_chopper_cycle, 2)
    info.phase_field_chop->set_value,STRTRIM(info.current_chopper_phase, 2)
  ENDIF
  WIDGET_CONTROL, info.chopper_freq_field, SET_VALUE=STRTRIM(info.current_chopper_freq, 2)
  IF info.chop_blade_index NE info.chopper_blade_index_old THEN BEGIN
    WIDGET_CONTROL, info.blade_field_chop, SET_DROPLIST_SELECT = info.chop_blade_index
    rrcat_soloist_update_chopper_blade_fields, info, info.chop_blade_index
  ENDIF
  WIDGET_CONTROL, info.enable_bgroup_chop, SET_VALUE = info.chopper_enable

END