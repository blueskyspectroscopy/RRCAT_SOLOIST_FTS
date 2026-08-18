;+
; NAME:
; rrcat_soloist_change_fts_scan_mode
;
; PURPOSE:
; This procedure updates the RRCAT Control GUI with the curent scanning
; mode. Parts of the GUI are sensitized/desensitized based on the 
; chosen scanning mode.
;
; CATEGORY:
; SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_soloist_change_fts_scan_mode, Info, fts_scan_mode
;
; INPUTS:
; Info: The main info block from SOLOIST_FTS.pro
; fts_scan_mode: The new scanning mode
;
; MODIFICATION HISTORY:
; 12 Jul 2019 (TRF): Removed sia_base references as step and inegrate is now just slow scanning
; 12 Jul 2019 (TRF): Updates the GUI to show current scan mode
;-
PRO rrcat_soloist_change_fts_scan_mode, info, fts_scan_mode

  IF fts_scan_mode EQ 'Rapid Scan' THEN BEGIN
    RRCAT_SOLOIST_FTS_DESENSITIZE, info, /SAI
  ENDIF
  IF fts_scan_mode EQ 'Step and Integrate' THEN BEGIN
    RRCAT_SOLOIST_FTS_SENSITIZE, info, /SAI
    ;WIDGET_CONTROL, info.sai_base,sensitive=1
    IF info.simLia EQ 0 THEN BEGIN
      rc = RRCAT_SOLOIST_FTS_load_lia_settings(info)
      RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
    ENDIF
  ENDIF
  id=widget_info(info.tlb,find_by_uname='scan_mode')
  widget_control,id,set_value=STRTRIM(fts_scan_mode, 2)

END