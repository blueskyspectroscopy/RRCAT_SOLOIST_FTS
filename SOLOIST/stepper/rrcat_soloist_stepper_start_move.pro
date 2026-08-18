;+
; NAME:
; RRCAT_soloist_stepper_start_move
;
; PURPOSE:
; This procedure starts a slew the selected motor in the selected direction.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rc = RRCAT_soloist_stepper_start_move(info, theMotor, direction, /debug)
;
; INPUTS:
; Info: The main info block from SOLOIST_FTS.pro
; theMotor: The chosen stepper motor
; direction: The direction of travel
; debug: Keyword input that print status messages to console/logger
;
; MODIFICATION HISTORY:
; 07 Jul 2019 (TRF): Hacked in a fix for the transmission HEB
; 08 Jul 2019 (TRF): Removed the hack
;-
FUNCTION RRCAT_soloist_stepper_start_move, info, theMotor, direction, debug=debug

  ;  maxTravels = [ $
  ;    6300, $
  ;    6300, $
  ;    6300, $
  ;    12795, $
  ;    12920]
  maxTravels = info.maxTravels
  maxTravel = maxTravels[theMotor]

  IF NOT KEYWORD_SET(debug) THEN debug = 0

  default_idle_current = 300

  sm = info.stepperMotors

  ;
  ; Check the limit sensors for this motor
  ;
  thisMotor = sm[theMotor]
  IF debug GT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Limit-: ' + STRTRIM(thisMotor.limitMinus, 2) +  ' Limit+: ' + STRTRIM(thisMotor.limitPlus, 2)
  ENDIF
  IF thisMotor.limitMinus EQ 0 AND thisMotor.limitPlus EQ 0 THEN BEGIN
    result=dialog_message('Warning!! Motor ' + STRTRIM(thisMotor.motor, 2) + ' is starting its move and is not at either limit!',title='Mirror Warning')
  ENDIF
  ;
  ; Check the state for this motor
  ;
  startPos = thisMotor.location
  info.startPos = startPos
  motorState = thisMotor.state
  IF debug GT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Position: ' + STRTRIM(startPos, 2)
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' State: ' + STRTRIM(motorState, 2)
  ENDIF
  IF motorState NE 0 THEN BEGIN
    IF info.debug EQ 1 THEN SOLOIST_FTS_MESSAGE, info, 'Motor State: ' + STRTRIM(motorState, 2)
    return, -1
  ENDIF

  IF direction EQ 0 AND thisMotor.limitMinus EQ 1 THEN BEGIN
    result=dialog_message('Motor ' + STRTRIM(thisMotor.motor, 2) + ' is already at the -ve limit.', /INFORMATION)
    return, -1
  ENDIF
  IF direction EQ 1 AND thisMotor.limitPlus EQ 1 THEN BEGIN
    result=dialog_message('Motor ' + STRTRIM(thisMotor.motor, 2) + ' is already at the +ve limit.', /INFORMATION)
    return, -1
  ENDIF
  IF info.debug EQ 1 THEN SOLOIST_FTS_MESSAGE, info, 'Preparing to move motor ' + STRTRIM(thisMotor.motor, 2) + ' resetting and initializing.'
  ;
  ; Reset motors and initialize
  ;
  rrcat_stepper_reset_and_init, info
  info.startPos = 0
  retStr = info.stepper->setMotorCurrentIdle(default_idle_current, motor=thisMotor.motor)
  data = info.stepper->slew(thisMotor.motor, direction)
  return, 0
END