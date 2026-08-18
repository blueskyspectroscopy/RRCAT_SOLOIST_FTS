;+
; NAME:
; RRCAT_CONVERT_STEP_STATUS_TO_STRING
;
; PURPOSE:
; This function converts the stepper status integer into a more comprehensible string.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; str = RRCAT_CONVERT_STEP_STATUS_TO_STRING(stat)
;
; INPUTS:
; stat:  The status integer
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;-
FUNCTION rrcat_convert_step_status_to_string, stat

  CASE stat OF
    0: statStr = 'IDLE'
    1: statStr = 'MOVING'
    2: statStr = 'RAMPING DOWN'
    3: statStr = 'SLEWING'
    4: statStr = 'QUICK STOP'
    5: statStr = 'REVERSE SLEW'
    6: statStr = 'GOTO'
    7: statStr = 'VECTOR MOTION'
    8: statStr = 'MOVING'
    ELSE: statStr = 'UNKNOWN'
  ENDCASE
  return, statStr

END