;+
; NAME:
; RRCAT_SET_FTS_POSITION
;
; PURPOSE:
; This procedure calls the procedure to execute the move of the
; FTS flip mirror to the desired position.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SET_FTS_POSITION, info, ftsType
;
; INPUTS:
; info:  The main info structure.
; ftsType: The selected FTS type.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;   TODO: Finalize the motor and direction for each fts type.
;-
PRO rrcat_set_fts_position, info, ftsType, steps=steps

  IF ftsType EQ "Michelson" THEN direction = 1
  IF ftsType EQ "Martin-Puplett" THEN direction = 0
  IF info.simStepper EQ 0 THEN BEGIN
    motor = 3
    if info.debug EQ 1 then begin
      SOLOIST_FTS_MESSAGE, info, 'Moving mirror ' + STRTRIM(motor, 2) + ' in position for ('+ftsType+')'
    endif
    RRCAT_soloist_stepper_move_motor, info, motor, direction, debug=info.debug
  ENDIF

  RETURN

END
