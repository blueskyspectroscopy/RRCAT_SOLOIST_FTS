;+
; NAME:
; RRCAT_PARSE_CHOPPER_STRING
;
; PURPOSE:
; This function parses the string returned by the chopper controller
; to a more digestible form. 
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; struct = rrcat_parse_chopper_string(str, info)
;
; INPUTS:
; str: The string to be parsed.
; info:  the main info block structure.
; 
; KEYWORDS:
; 
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 21 2018.
;-

function rrcat_parse_chopper_string, str, info, GET=GET, SET=SET

  ;
  ; Get the length of the string
  ;
  len = STRLEN(str)
  
  ;
  ; Find the '> ' characters
  ;
  pos = STRPOS(str, '> ')
  
  ;
  ; If pos ne len-2 then this was an error
  ;
  IF pos ne len-2 THEN BEGIN
    pos2 = STRPOS(str, '> ', /REVERSE_SEARCH)
    errStr = STRMID(str, pos+2, pos2-(pos+2)-1)
    IF errStr EQ 'CMD_ARG_RANGE_ERR' THEN BEGIN
      SOLOIST_FTS_MESSAGE, info, 'Error! Command out of range.'
      RETURN, -1
    ENDIF
  ENDIF
  IF KEYWORD_SET(GET) THEN BEGIN
    qpos = STRPOS(str, '?')
    val = STRMID(str, qpos+2, pos-(qpos+2)-1)
  ENDIF
  IF KEYWORD_SET(SET) THEN BEGIN
    qpos = STRPOS(str, '=')
    val = STRMID(str, qpos+1, pos-(qpos+2)-1)
  ENDIF
  cmd = STRMID(str, 0,  qpos)
  
  case cmd of 
    'freq': begin
       info.current_chopper_freq = LONG(val)
     end
     'blade': begin
       info.chop_blade_index = FIX(val)
     end
     'refoutfreq': begin
       info.current_chopper_refoutfreq = LONG(val)
     end
     'nharmonic': begin
       info.current_chopper_nharmonic = FIX(val)
     end
     'dharmonic': begin
       info.current_chopper_dharmonic = FIX(val)
     end
     'phase': begin
       info.current_chopper_phase = FIX(val)
     end
     'oncycle': begin
       info.current_chopper_cycle = FIX(val)
     end
     'output': begin
       info.current_chopper_outputrefmode = FIX(val)
     end
     'ref': begin
       info.current_chopper_refmode = FIX(val)
     end
     'id': begin
       info.current_chopper_id = val
     end
     'enable': begin
       info.chopper_enable = FIX(val)
     end
     'input': begin
       info.current_chopper_extreffreq = LONG(val)
     end
  endcase
end