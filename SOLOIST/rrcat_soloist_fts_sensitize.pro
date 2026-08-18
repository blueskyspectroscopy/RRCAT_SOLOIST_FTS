
;+
; NAME:
;	RRCAT_SOLOIST_FTS_SENSITIZE
;
; PURPOSE:
;	This procedure sensitizes the widgets that were desensitized
;	during a scan.
;
; CATEGORY:
;	RRCAT_SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_SENSITIZE, Info
;
; INPUTS:
;	Info:	The main info block from RRCAT_SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Mar 8 2018. Based on SOLOIST_FTS_SENSITIZE.pro
;-


Pro RRCAT_SOLOIST_FTS_SENSITIZE, info, STEPPER=STEPPER, SAI=SAI, RELAY=RELAY, CHOPPER=CHOPPER, LIA=LIA

  IF KEYWORD_SET(STEPPER) THEN BEGIN
    IF info.simStepper EQ 0 THEN BEGIN
      id = info.tab_base_stepper
      widget_control,id,/sens
    ENDIF
  ENDIF

  IF KEYWORD_SET(RELAY) THEN BEGIN
    IF info.simRelay EQ 0 THEN BEGIN
      id = info.tab_base_relay
      widget_control,id,/sens
    ENDIF
  ENDIF

  IF KEYWORD_SET(CHOPPER) THEN BEGIN
    IF info.simChopper EQ 0 THEN BEGIN
      id = info.tab_base_chopper
      widget_control,id,/sens
    ENDIF
  ENDIF

  IF KEYWORD_SET(LIA) THEN BEGIN
    IF info.simLia EQ 0 THEN BEGIN
      id = info.tab_base_lia
      widget_control,id,/sens
    ENDIF
  ENDIF

  IF KEYWORD_SET(SAI) THEN BEGIN
    IF info.simChopper EQ 0 THEN BEGIN
      id = info.tab_base_chopper
      widget_control,id,/sens
    ENDIF
    IF info.simLia EQ 0 THEN BEGIN
      id = info.tab_base_lia
      widget_control,id,/sens
    ENDIF
  ENDIF

end