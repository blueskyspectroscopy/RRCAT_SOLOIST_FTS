
;+
; NAME:
;	RRCAT_SOLOIST_FTS_DESENSITIZE
;
; PURPOSE:
;	This procedure desensitizes input widgets during a scan.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_DESENSITIZE, Info
;
; INPUTS:
;	Info:	The main info block from RRCAT_SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Mar 8 2018. Based on SOLOIST_FTS_DESENSITIZE.pro
;-


Pro RRCAT_SOLOIST_FTS_DESENSITIZE, info, STEPPER=STEPPER, CHOPPER=CHOPPER, LIA=LIA, RELAY=RELAY, SAI=SAI
  IF KEYWORD_SET(STEPPER) THEN BEGIN
      id = info.tab_base_stepper
      widget_control,id,sens=0
  ENDIF
  IF KEYWORD_SET(CHOPPER) THEN BEGIN
      id = info.tab_base_chopper
      widget_control,id,sens=0
 ENDIF
 IF KEYWORD_SET(LIA) THEN BEGIN
   id = info.tab_base_lia
   widget_control,id,sens=0
 ENDIF
  IF KEYWORD_SET(RELAY) THEN BEGIN
      id = info.tab_base_relay
      widget_control,id,sens=0
  ENDIF
  IF KEYWORD_SET(SAI) THEN BEGIN
      id = info.tab_base_chopper
      widget_control,id,sens=0
      id = info.tab_base_lia
      widget_control,id,sens=0
  ENDIF


end