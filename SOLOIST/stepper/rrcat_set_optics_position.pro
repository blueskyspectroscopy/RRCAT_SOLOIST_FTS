;+
; NAME:
; RRCAT_SOLOIST_SET_OPTICS_POSITION
;
; PURPOSE:
; This procedure calls the procedure to execute the move of the
; MOC flip mirror to the desired position.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_set_optics_position, info, opticsType
;
; INPUTS:
; info:  The widget info structure
; opticsType: String denoting the optics to be adjusted
;
; MODIFICATION HISTORY:
;   Written by: TRF, Jan 7 2018.
;-
PRO rrcat_set_optics_position, info, opticsType, steps=steps
  motor = 4
  case opticsType of
    'Reflection': BEGIN
      direction = 0; B- limit
    END
    'Transmission': BEGIN
      direction = 0; B- limit
    END
    'Intermediate':BEGIN
      direction = 1; B- limit
    END
    ELSE: BEGIN
      PRINT, "Unknown opticsType value: "+opticsType
    END
  endcase
  IF info.simStepper EQ 0 THEN BEGIN
    IF info.debug NE 0 THEN BEGIN
      SOLOIST_FTS_MESSAGE, info, 'Moving mirror ' + STRTRIM(motor, 2) + ' in position for ('+opticsType+')'
    ENDIF
    RRCAT_soloist_stepper_move_motor, info, motor, direction, debug=info.debug
  ENDIF
  RETURN

END