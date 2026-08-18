;+
; NAME:
; RRCAT_GET_DET_POSITION
;
; PURPOSE:
; This function returns the position of the detector flip mirror based on the
; selected optics type. The optics type is required becaues the detector
; position is dependent on the selected optics.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; str = RRCAT_GET_DET_POSITION(info, opticsType)
;
; INPUTS:
; info:  The main info structure.
; opticsType: The selected optics type.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;-
FUNCTION rrcat_get_det_position, info, opticsType

  det_position = ''
  det_positions = [['HEB', 'TES', ' '], ['MCT', 'Pyro-1', 'Pyro-2']]
  IF info.simStepper EQ 0 THEN BEGIN
    latchStr = info.stepper->getLimitState()
    latchStr = rrcat_stepper_parse_string(latchStr, info, /LIMITSTATE)
    stepperMotors = info.stepperMotors
    case opticsType of
      'Reflection': BEGIN
        IF stepperMotors[1].limitMinus EQ 1 THEN det_position = det_positions[*, 0] ; X- limit
        IF stepperMotors[1].limitPlus EQ 1 THEN det_position = det_positions[*, 1] ; X+ limit
      END
      'Transmission': BEGIN
        IF stepperMotors[2].limitMinus EQ 1 THEN det_position = det_positions[*, 1] ; Y- limit
        IF stepperMotors[2].limitPlus EQ 1 THEN det_position = det_positions[*, 0] ; Y+ limit
      END
      'Intermediate':BEGIN
        IF stepperMotors[0].limitMinus EQ 1 THEN det_position = det_positions[*, 0] ; W- limit
        IF stepperMotors[0].limitPlus EQ 1 THEN det_position = det_positions[*, 1] ; W+ limit
      END
      ELSE: BEGIN
        PRINT, "Unknown opticsType value: "+opticsType
      END
    endcase
    RETURN, det_position
  ENDIF ELSE BEGIN
    RETURN, det_positions[*, 0]
  ENDELSE

  

END
