;+
; NAME:
; RRCAT_SOLOIST_UPDATE_RELAY_STATUS
;
; PURPOSE:
; This procedure updates the GUI relay status field.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_UPDATE_RELAY_STATUS, info
;
; INPUTS:
; info:  the main info block structure.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 26 2018.
;   24 May 2018 (TRF): Now updates the non-exclusive checkboxes too.
;-
PRO rrcat_soloist_update_relay_status, info
  ;print, "HK_TIMER: "+info.relay_status
  relay_status_vector = INTARR(7)
  relay_status = FIX(info.relay_status)
  relay_status_vector[0] = ((relay_status AND 1) GT 0) ? 1 : 0
  relay_status_vector[1] = ((relay_status AND 2) GT 0) ? 1 : 0
  relay_status_vector[2] = ((relay_status AND 4) GT 0) ? 1 : 0
  relay_status_vector[3] = ((relay_status AND 8) GT 0) ? 1 : 0
  relay_status_vector[4] = ((relay_status AND 16) GT 0) ? 1 : 0
  relay_status_vector[5] = ((relay_status AND 32) GT 0) ? 1 : 0
  relay_status_vector[6] = ((relay_status AND 64) GT 0) ? 1 : 0
  info.relay_status_vector = relay_status_vector
  WIDGET_CONTROL, info.enable_bgroup_relay, SET_VALUE = relay_status_vector
  WIDGET_CONTROL, info.relay_status_field, SET_VALUE = info.relay_status


END