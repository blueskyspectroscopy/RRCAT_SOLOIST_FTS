;+
; NAME:
; RRCAT_PARSE_RELAY_STRING
;
; PURPOSE:
; This function parses the string returned by the relay controller
; to a more digestible form. 
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; struct = rrcat_parse_relay_string(str, info)
;
; INPUTS:
; str: The string to be parsed.
; 
; KEYWORDS:
; 
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 26 2018.
;-

function rrcat_parse_relay_string, str
  IF str EQ '-1' OR str EQ '' THEN BEGIN
    return, '-1'
  ENDIF
  
  ;
  ; Get the length of the string
  ;
  len = STRLEN(str)
  
  ;
  ; Format of the returned string is:
  ; #AA Val/cr/lf
  ; Where AA is the address of the relay controller.
  ; So the value of interest starts at character 4 and
  ; ends at STRLEN-2
  startPos = 4
  valLen = len-startPos-2
  val = STRMID(str, startPos, valLen)
  ;print, str, val, startPos, valLen
  return, val
end