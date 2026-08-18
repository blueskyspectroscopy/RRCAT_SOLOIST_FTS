;+
; NAME:
;	RRCAT_SOLOIST_FTS_update_hk_status
;
; PURPOSE:
;	This procedure updates the housekeeping fields in the RRCAT_SOLOIST GUI.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_update_hk_status, Info
;
; INPUTS:
;	Info:	The main infoblock from SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Dec 15 2017.
; 	2018 Feb 28 (TRF): Added stepper->getStatus(), stepper->getMotorState()
;   2018 May 17 (TRF): Added format codes for HK status fields
;   2019 Jul 30 (TRF): Modified format codes for pressure status fields
;   2019 Jul 30 (TRF): Added timing diagnositcs
;   2019 Aug 01 (TRF): Moved relay to NO_SAI
;   2019 Aug 13 (TRF): Removed HK calls to stepper unless keyword STEPPER is set
;   2019 Aug 27 (TRF): Added debug keyword to RRCAT_SOLOIST_LIA_UPDATE_FIELDS
;   2019 Aug 28 (TRF): Removed debug as casue of slowdown has been discovered.
;   2019 Aug 29 (TRF): Removed tic()/toc() pairs that were used to find cause of slowdown
;-

pro RRCAT_SOLOIST_FTS_update_hk_status,info, NO_SAI=NO_SAI, STEPPER=STEPPER
;  IF info.debug THEN clock=tic('housekeeping')
  id=widget_info(info.tlb,find_by_uname='fts_temp_1')
  widget_control,id,set_value=STRING(info.housekeeping.fts_temp_1, FORMAT = '(6F6.1)')
  id=widget_info(info.tlb,find_by_uname='fts_temp_2')
  widget_control,id,set_value=STRING(info.housekeeping.fts_temp_2, FORMAT = '(6F6.1)')
  id=widget_info(info.tlb,find_by_uname='fts_pressure')
  widget_control,id,set_value=STRING(info.housekeeping.fts_pressure, FORMAT = '(10F10.6)')
  ;  id=widget_info(info.tlb,find_by_uname='det_temp_1')
  ;  widget_control,id,set_value=STRTRIM(info.housekeeping.det_temp_1, 2)
  ;  id=widget_info(info.tlb,find_by_uname='det_temp_2')
  ;  widget_control,id,set_value=STRTRIM(info.housekeeping.det_temp_2, 2)
  ;  id=widget_info(info.tlb,find_by_uname='det_temp_3')
  ;  widget_control,id,set_value=STRTRIM(info.housekeeping.det_temp_3, 2)
  id=widget_info(info.tlb,find_by_uname='det_pressure')
  widget_control,id,set_value=STRING(info.housekeeping.det_pressure, FORMAT = '(10F10.6)')
  id=widget_info(info.tlb,find_by_uname='det_temp')
  widget_control,id,set_value=STRING(info.housekeeping.det_temp, FORMAT = '(6F6.1)')
  IF KEYWORD_SET(STEPPER) THEN BEGIN
    IF info.simStepper EQ 0 AND OBJ_VALID(info.stepper) THEN BEGIN
      rrcat_soloist_update_stepper_status, info
    ENDIF
  ENDIF
  IF info.simRelay EQ 0 AND OBJ_VALID(info.relay) THEN BEGIN
    RRCAT_SOLOIST_UPDATE_RELAY_FIELDS, info
    rrcat_soloist_update_relay_status, info
  ENDIF
  IF NOT KEYWORD_SET(NO_SAI) THEN BEGIN
    IF info.simChopper EQ 0 AND OBJ_VALID(info.chopper) THEN BEGIN
      ;    data = info.chopper->getFreq()
      ;    freq = rrcat_parse_chopper_string(data, info, /GET)
      ;    IF freq EQ -1 then return
      ;    info.current_chopper_freq = freq
      RRCAT_SOLOIST_UPDATE_CHOPPER_FIELDS, info
      rrcat_soloist_update_chopper_status, info
    ENDIF
    IF info.simLia EQ 0 AND OBJ_VALID(info.lia) THEN BEGIN
      RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
    ENDIF
;    IF info.debug THEN TOC, clock
  ENDIF
;  IF info.debug THEN TOC, clock
  SOLOIST_FTS_MESSAGE,info,'Current memory (MB): '+strtrim(MEMORY(/CURRENT)/1024./1024.,2)
;  IF info.debug THEN TOC, clock
  return
end
