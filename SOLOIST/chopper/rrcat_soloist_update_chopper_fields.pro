;+
; NAME:
; RRCAT_SOLOIST_UPDATE_CHOPPER_FIELDS
;
; PURPOSE:
; This procedure queries the chopper controller and 
; updates the approprite field in the RRCAT SOLOIST
; info block with the results.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_UPDATE_CHOPPER_FIELDS, info
;
; INPUTS:
; info: The main info structure
;
; KEYWORDS:
; ALL: Set this keyword to update all fields. By default only the
; frequency, enable, and blade fields are updated.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 26 2018.
;-
PRO RRCAT_SOLOIST_UPDATE_CHOPPER_FIELDS, info, ALL=ALL

  data = info.chopper->getFreq()
  retVal = rrcat_parse_chopper_string(data, info, /GET)
  IF retVal EQ -1 then return

  data = info.chopper->getEnable()
  ;print, 'Data returned from Chpper controller ' + data
  retVal = rrcat_parse_chopper_string(data, info, /GET)  
  IF retVal EQ -1 then return

  data = info.chopper->getBlade()
  info.chopper_blade_index_old = info.chop_blade_index
  retVal = rrcat_parse_chopper_string(data, info, /GET)
  IF retVal EQ -1 then return

  IF KEYWORD_SET(ALL) THEN BEGIN
    data = info.chopper->getOnCycle()
    retVal = rrcat_parse_chopper_string(data, info, /GET)
    IF retVal EQ -1 then return

    data = info.chopper->getdHarmonic()
    retVal = rrcat_parse_chopper_string(data, info, /GET)
    IF retVal EQ -1 then return

    data = info.chopper->getHarmonic()
    retVal = rrcat_parse_chopper_string(data, info, /GET)
    IF retVal EQ -1 then return

    ;  data = info.chopper->getHarmonic()
    ;  refoutfreq = rrcat_parse_chopper_string(data, info, /GET)
    ;  IF nharmonic EQ -1 then return
    ;  info.current_chopper_refoutfreq = refoutfreq
  ENDIF

END