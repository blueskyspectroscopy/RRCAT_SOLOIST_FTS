;+
; NAME:
; RRCAT_SET_DET_POSITION
;
; PURPOSE:
; This procedure calls the procedure to execute the move of the
; detector flip mirror to the desired position. NB first, the
; optics type is determined so that only the one of the three
; possibilities is actually moved.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SET_DET_POSITION, info, opticsType, detType
;
; INPUTS:
; info:  The main info structure.
; opticsType: The selected optics type.
; detType: The selected detector.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;   TODO: Finalize the motors and directions for each det type.
;-
PRO rrcat_set_det_position, info, opticsType, detType, steps=steps
  IF detType EQ "Pyro-1" THEN direction = 1
  IF detType EQ "Pyro-2" THEN direction = 1
  IF detType EQ "MCT" THEN direction = 1
  IF detType EQ "HEB" THEN direction = 0
  IF detType EQ "TES" THEN direction = 0
  case opticsType of
    'Reflection': BEGIN
      motor = 1; X- limit
    END
    'Transmission': BEGIN
      motor = 2; Y- limit
      IF direction EQ 1 THEN BEGIN
        direction = 0
      ENDIF ELSE BEGIN
        direction = 1
      ENDELSE
    END
    'Intermediate':BEGIN
      motor = 0; W- limit
    END
    ELSE: BEGIN
      PRINT, "Unknown opticsType value: "+opticsType
    END
  endcase
  IF info.simStepper EQ 0 THEN BEGIN
    IF info.debug NE 0 THEN BEGIN
      SOLOIST_FTS_MESSAGE, info, 'Moving mirror ' + STRTRIM(motor, 2) + ' ('+opticsType+') in position for '+detType 
    ENDIF
    RRCAT_soloist_stepper_move_motor, info, motor, direction, debug=info.debug
  ENDIF

  RETURN

END
