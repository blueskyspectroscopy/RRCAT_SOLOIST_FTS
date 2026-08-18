;+
; NAME:
; RRCAT_GET_FTS_POSITION
;
; PURPOSE:
; This function queries the stepper motors regarding the position
; of the FTS flip mirror.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; fts_position = RRCAT_GET_FTS_POSITION(info)
;
; INPUTS:
; info:  The main info structure.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;-
FUNCTION rrcat_get_fts_position, info

  fts_position = ''
  fts_positions = ['Michelson', 'Martin-Puplett']
  IF info.simStepper EQ 0 THEN BEGIN
    latchStr = info.stepper->getLimitState()
    latchStr = rrcat_stepper_parse_string(latchStr, info, /LIMITSTATE)
    stepperMotors = info.stepperMotors
    IF info.stepperMotors[3].limitMinus EQ 1 THEN fts_position = fts_positions[1] ; A- limit
    IF info.stepperMotors[3].limitPlus EQ 1 THEN fts_position = fts_positions[0] ; A+ limit
  ENDIF ELSE BEGIN
    fts_position = fts_positions[0]
  ENDELSE

  RETURN, fts_position

END
