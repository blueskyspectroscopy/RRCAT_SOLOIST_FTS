;+
; NAME:
; rrcat_soloist_check_stepper_move_status
;
; PURPOSE:
; This funtion checks the state of motor after it has been given
; a slew command. Returns 1 if the motor is still moving or should 
; still be moving, 0 otherwise.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rc = rrcat_soloist_check_stepper_move_status(Info)
;
; INPUTS:
; Info: The main info block from SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 04 Jul 2019 -- TRF: Changed the move threshold to 10% more than expected steps (was 50%)
; 07 Jul 2019 -- TRF: Hacked in to let motor 2 move in +ve direction even it limit is active
; 07 Jul 2019 -- TRF: Removed the hack
;-
FUNCTION rrcat_soloist_check_stepper_move_status, info
  ; TODO: These values should be in the info structure
  maxTravels = info.maxTravels
  theMotor = info.selected_motor_index
  sm = info.stepperMotors
  startPos = info.startPos

  thisMotor = sm[theMotor]
  maxTravel = maxTravels[theMotor]
  motorState = thisMotor.state
  thisPos = thisMotor.location
  direction = thisMotor.direction
  IF info.debug GT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' State: ' + STRTRIM(thisMotor.state, 2) + $
      ' Location: ' + STRTRIM(thisPos, 2) + ' Steps: ' + STRTRIM(ABS(thisPos-startPos), 2)
  ENDIF
  IF motorState EQ 0 THEN BEGIN
    ;
    ; IDL structure for the motor thinks it is IDLE,
    ; check to see if it has reached a limit. Motor is idle.
    ;
    status = info.stepper->getLimitState()
    str = rrcat_stepper_parse_string(status, info, /LIMITSTATE)
    sm = info.stepperMotors
    limitMinus = sm[theMotor].limitMinus
    IF direction EQ 0 AND limitMinus EQ 1 THEN BEGIN
      retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
      endPos = thisMotor.location
      IF info.debug GT 0 THEN BEGIN
        SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Start pos: ' + STRTRIM(startPos, 2) + ' End pos: ' + STRTRIM(endPos, 2) + ' Total steps: ' + STRTRIM(ABS(endPos-startPos), 2)
      ENDIF
      return, 0
    ENDIF
    limitPlus = sm[theMotor].limitPlus
    IF direction EQ 1 AND limitPlus EQ 1 THEN BEGIN
      retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
      endPos = thisMotor.location
      IF info.debug GT 0 THEN BEGIN
        SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Start pos: ' + STRTRIM(startPos, 2) + ' End pos: ' + STRTRIM(endPos, 2) + ' Total steps: ' + STRTRIM(ABS(endPos-startPos), 2)
      ENDIF
      return, 0
    ENDIF
    ;
    ; Motor idle but limit was not reached, start another slew and return
    ;

    IF info.debug GT 0 THEN BEGIN
      status = info.stepper->getStatus(/LATCH)
      str = rrcat_stepper_parse_string(status, info, /LATCH)
      ;SOLOIST_FTS_MESSAGE, info, str
      SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' stopped before reaching its desired limit. Restarting motion.'
    ENDIF
    ;STOP
    data = info.stepper->slew(thisMotor.motor, direction)
    return, 1
  ENDIF
  IF motorState LT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' is in an ambiguous state. Stopping motion.'
    retStr = info.stepper->stop(motor=thisMotor.motor)
    retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
    return, 0
  ENDIF
  ;
  ; Motor is still moving the number of steps that we have traveled.
  ;
  IF ABS(thisPos-startPos) GT 1.1 * maxTravel THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' has travelled a distance greater than its expected maximum. Stopping motor'
    rc = DIALOG_MESSAGE('Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' has travelled a distance greater than its expected maximum. Stopping motor')
    retStr = info.stepper->stop(motor=thisMotor.motor)
    retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
    IF info.debug GT 0 THEN BEGIN
      SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Start pos: ' + STRTRIM(startPos, 2) + ' End pos: ' + STRTRIM(thisPos, 2) + ' Total steps: ' + STRTRIM(ABS(thisPos-startPos), 2)
    ENDIF
    return, 0
  ENDIF
  return, 1

END