;+
; NAME:
; RRCAT_GET_OPTICS_POSITION
;
; PURPOSE:
; This function queries the stepper motors regarding the position
; of the optics flip mirror.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; optics_position = RRCAT_GET_OPTICS_POSITION(info)
;
; INPUTS:
; info:  The main info structure.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;
;-
FUNCTION rrcat_get_optics_position, info
  optics_position = ''
  optics_positions = [['Reflection', 'Transmission'], ['Intermediate', 'Intermediate']]
  IF info.simStepper EQ 0 THEN BEGIN
    limitStr = info.stepper->getLimitState()
    limitStr = rrcat_stepper_parse_string(limitStr, info, /LIMITSTATE)
    stepperMotors = info.stepperMotors
    IF info.stepperMotors[4].limitMinus EQ 1 THEN optics_position = optics_positions[*, 0] ; B- limit
    IF info.stepperMotors[4].limitPlus EQ 1 THEN optics_position = optics_positions[*, 1] ; B+ limit
  ENDIF ELSE BEGIN
    optics_position = optics_positions[*, 0]
  ENDELSE

  RETURN, optics_position

END
