;+
; NAME:
; RRCAT_ENABLE_FTS_TAB
;
; PURPOSE:
; This procedure swaps the gui fields in the main info
; block for the two FTS configurations.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_ENABLE_FTS_TAB, info, fts
;
; INPUTS:
; info: The main info block structure.
; fts: The selected FTS configuration.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018.
;   17 May 2018 (TRF): Changed to Mid Infrared/Far Infrared and added LIA tab
;   
;-
PRO rrcat_enable_fts_tab, info, fts

  IF fts EQ 0 THEN fts_select = 'Michelson'
;  IF fts EQ 1 THEN fts_select = 'MP'
  IF fts EQ 1 THEN fts_select = 'SOLOIST'
  IF fts EQ 2 THEN fts_select = 'Stepper Motors'
  ;IF fts EQ 4 THEN fts_select = 'Stepper Limits'
  IF fts EQ 3 THEN fts_select = 'Chopper'
  IF fts EQ 4 THEN fts_select = 'LIA'
  IF fts EQ 5 THEN fts_select = 'Relays'
  
  IF fts EQ 1 OR fts EQ 2 OR fts EQ 3 or fts EQ 4 or fts EQ 5 or fts EQ 6 OR fts EQ 7 THEN RETURN
  
  ;print, "FTS_SELECT: "+fts_select

  fts_fields = info.fts_fields
  IF fts_select EQ 'Michelson' THEN BEGIN
;    drive_status_id = fts_fields.drive_status_id_sw
;    Axis_status_id = fts_fields.Axis_status_id_sw
;    fault_id = fts_fields.fault_id_sw
    tab_base = fts_fields.tab_base_sw
    abort_id = fts_fields.abort_id_sw
    speed_field = fts_fields.speed_field_sw
    resolution_field = fts_fields.resolution_field_sw
    ds_field = fts_fields.ds_field_sw
    sym_button = fts_fields.sym_button_sw
    nyquist_id = fts_fields.nyquist_id_sw
    max_freq_field = fts_fields.max_freq_field_sw
    scans_field = fts_fields.scans_field_sw
;    step_field = fts_fields.step_field_sw
  ENDIF
  IF fts_select EQ 'MP' THEN BEGIN
;    drive_status_id = fts_fields.drive_status_id_lw
;    Axis_status_id = fts_fields.Axis_status_id_lw
;    fault_id = fts_fields.fault_id_lw
    tab_base = fts_fields.tab_base_lw
    abort_id = fts_fields.abort_id_lw
    speed_field = fts_fields.speed_field_lw
    resolution_field = fts_fields.resolution_field_lw
    ds_field = fts_fields.ds_field_lw
    sym_button = fts_fields.sym_button_lw
    nyquist_id = fts_fields.nyquist_id_lw
    max_freq_field = fts_fields.max_freq_field_lw
    scans_field = fts_fields.scans_field_lw
 ;   step_field = fts_fields.step_field_lw
  ENDIF
;  info.drive_status_id = drive_status_id
;  info.Axis_status_id = Axis_status_id
;  info.fault_id = fault_id
  info.tab_base = tab_base
  info.abort_id = abort_id
  info.speed_field = speed_field
  info.resolution_field = resolution_field
  info.ds_field = ds_field
  info.sym_button = sym_button
  info.nyquist_id = nyquist_id
  info.max_freq_field = max_freq_field
  info.scans_field = scans_field
;  info.step_field = step_field
  
  result=RRCAT_SOLOIST_FTS_load_settings(info)
  ;info.FTS_selected = fts_select
END