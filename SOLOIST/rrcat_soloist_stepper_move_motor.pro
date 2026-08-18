;+
; NAME:
; RRCAT_soloist_stepper_move_motor
;
; PURPOSE:
; This procedure slews the selected motor in the selected direction
; until it reaches its limit.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_soloist_stepper_move_motor, info, theMotor, direction, /debug
;
; INPUTS:
; Info: The main info block from SOLOIST_FTS.pro
; theMotor: The chosen stepper motor
; direction: The direction of travel
; debug: Keyword input that print status messages to console/logger
;
; MODIFICATION HISTORY:
;
;-
PRO RRCAT_soloist_stepper_move_motor, info, theMotor, direction, debug=debug

  maxTravels = [ $
    6300, $
    6300, $
    6300, $
    12795, $
    12920]
  maxTravel = maxTravels[theMotor]

  IF NOT KEYWORD_SET(debug) THEN debug = 0

  default_idle_current = 300

  sm = info.stepperMotors

  ;  stepperMotors = REPLICATE({rrcat_motor_struct}, 5)
  ;  foreach motorStr, stepperMotors, index do begin
  ;    motorStr.motor = index
  ;    IF index GT 2 THEN motorStr.motor = index+1
  ;    ;motorStr.async = 1
  ;    stepperMotors[index] = motorStr
  ;  endforeach

  ;
  ; Check the limit sensors for this motor
  ;
  str = rrcat_stepper_parse_string(info.stepper->getLimitState(nRetries=nRetries), info, /LIMITSTATE, stepperMotors = sm)
  sm = info.stepperMotors
  thisMotor = sm[theMotor]
  IF debug GT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Limit-: ' + STRTRIM(thisMotor.limitMinus, 2) +  ' Limit+: ' + STRTRIM(thisMotor.limitPlus, 2)
  ENDIF
  IF thisMotor.limitMinus EQ 0 AND thisMotor.limitPlus EQ 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Warning!! Motor ' + STRTRIM(thisMotor.motor, 2) + ' is starting its move and is not at either limit!'
    rc = DIALOG_MESSAGE('Warning!! Motor ' + STRTRIM(thisMotor.motor, 2) + ' is starting its move and is not at either limit!')
    ;STOP
  ENDIF
  ;
  ; Check the state for this motor
  ;
  str = rrcat_stepper_parse_string(info.stepper->getStatus(nRetries=nRetries), info, /STATUS, stepperMotors = sm)
  sm = info.stepperMotors
  thisMotor = sm[theMotor]
  startPos = thisMotor.location
  IF debug GT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Position: ' + STRTRIM(thisMotor.location, 2)
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' State: ' + STRTRIM(thisMotor.state, 2)
  ENDIF
  IF thisMotor.state NE 0 THEN STOP

  IF direction EQ 0 AND thisMotor.limitMinus EQ 1 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor ' + STRTRIM(thisMotor.motor, 2) + ' is already at the -ve limit.'
    return
  ENDIF
  IF direction EQ 1 AND thisMotor.limitPlus EQ 1 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor ' + STRTRIM(thisMotor.motor, 2) + ' is already at the +ve limit.'
    return
  ENDIF
  rrcat_stepper_reset_and_init, info
  str = rrcat_stepper_parse_string(info.stepper->getStatus(nRetries=nRetries), info, /STATUS, stepperMotors = sm)
  sm = info.stepperMotors
  thisMotor = sm[theMotor]
  startPos = thisMotor.location
  retStr = info.stepper->setMotorCurrentIdle(default_idle_current, motor=thisMotor.motor)
  data = info.stepper->slew(thisMotor.motor, direction)
  needs_to_move = 1
  while needs_to_move EQ 1 do begin
    str = rrcat_stepper_parse_string(info.stepper->getMotorState(nRetries=nRetries), info, /MotorSTATE, stepperMotors = sm, /debug)
    sm = info.stepperMotors
    thisMotor = sm[theMotor]
    motorState = thisMotor.state
    IF motorState EQ 0 THEN BEGIN ; Motor is IDLE
      ;
      ; Check to see if we hit the limit
      ;
      str = rrcat_stepper_parse_string(info.stepper->getLimitState(nRetries=nRetries), info, /LIMITSTATE, stepperMotors = sm)
      sm = info.stepperMotors
      thisMotor = sm[theMotor]
      print, direction, motorState, thisMotor.limitMinus, thisMotor.limitPlus
      IF direction EQ 0 AND thisMotor.limitMinus EQ 1 THEN BEGIN
        retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
        break
      ENDIF
      IF direction EQ 1 AND thisMotor.limitPlus EQ 1 THEN BEGIN
        retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
        break
      ENDIF
      ;STOP
      IF debug GT 0 THEN BEGIN
        SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' stopped before reaching its desired limit. Restarting motion.'
      ENDIF
      data = info.stepper->slew(thisMotor.motor, direction)
      str = rrcat_stepper_parse_string(info.stepper->getStatus(nRetries=nRetries), info, /STATUS, stepperMotors = sm, debug = info.debug)
      sm = info.stepperMotors
      thisMotor = sm[theMotor]
      thisPos = thisMotor.location
      IF ABS(thisPos - startPos) GT 1.5 * maxTravel THEN BEGIN
        ; TODO Replace with a DIALOG_MESSAGE popup
        SOLOIST_FTS_MESSAGE, info, 'Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' has travelled a distance greater than its expected maximum.'
        rc = DIALOG_MESSAGE('Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' has travelled a distance greater than its expected maximum.')
        retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
        retStr = info.stepper->stop(motor = thisMotor.motor)
        return
      ENDIF

    ENDIF
    IF motorState LT 0 THEN BEGIN
      ; TODO Replace with a DIALOG_MESSAGE popup
      SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' is in an ambiguous state: ' + STRTRIM(motorState, 2)
      rc = DIALOG_MESSAGE('Motor: ' + STRTRIM(thisMotor.motor, 2) + ' is in an ambiguous state: ' + STRTRIM(motorState, 2))
      return
    ENDIF
    str = rrcat_stepper_parse_string(info.stepper->getStatus(nRetries=nRetries), info, /STATUS, stepperMotors = sm)
    sm = info.stepperMotors
    thisMotor = sm[theMotor]
    thisPos = thisMotor.location
    IF debug GT 0 THEN BEGIN
      SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' State: ' + STRTRIM(thisMotor.state, 2) + $
        ' Location: ' + STRTRIM(thisPos, 2) + ' Steps: ' + STRTRIM(ABS(thisPos-startPos), 2)
    ENDIF
    IF ABS(thisPos - startPos) GT 1.5 * maxTravel THEN BEGIN
      ; TODO Replace with a DIALOG_MESSAGE popup
      SOLOIST_FTS_MESSAGE, info, 'Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' has travelled a distance greater than its expected maximum.'
      rc = DIALOG_MESSAGE('Warning!! Motor: ' + STRTRIM(thisMotor.motor, 2) + ' has travelled a distance greater than its expected maximum.')
      retStr = info.stepper->setMotorCurrentIdle(0, motor=thisMotor.motor)
      retStr = info.stepper->stop(motor = thisMotor.motor)
      return
    ENDIF
  endwhile
  str = rrcat_stepper_parse_string(info.stepper->getStatus(nRetries=nRetries), info, /STATUS, stepperMotors = sm)
  sm = info.stepperMotors
  thisMotor = sm[theMotor]
  endPos = thisMotor.location
  IF debug GT 0 THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Motor: ' + STRTRIM(thisMotor.motor, 2) + ' Start pos: ' + STRTRIM(startPos, 2) + ' End pos: ' + STRTRIM(endPos, 2) + ' Total steps: ' + STRTRIM(ABS(endPos-startPos), 2)
  ENDIF
END