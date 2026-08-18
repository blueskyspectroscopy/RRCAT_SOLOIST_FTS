;+
; NAME:
; rrcat_soloist_convert_blade_index
;
; PURPOSE:
; This function converts the blade index to a number that is 
; understood by the chopper controller.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; struct = rrcat_soloist_convert_blade_index(index, /SELECT)
;
; INPUTS:
; index: The index of the GUI select menu.
;
; KEYWORDS:
; SELECT: Set this keyword to simply return the index.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 21 2018.
;-
FUNCTION rrcat_soloist_convert_blade_index, index, SELECT=SELECT
  IF NOT KEYWORD_SET(SELECT) THEN BEGIN
    return, index
  ENDIF

  case index of
    0: return, 1
    1: return, 6
  endcase

END