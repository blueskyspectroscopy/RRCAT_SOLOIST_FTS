;+
; NAME:
; rrcat_stepper_reset_and_init
;
; PURPOSE:
; This procedure resets the stepper motors and initializes them.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_stepper_reset_and_init, info, READ_VALUES=READ_VALUES, KEEP_IDLE_CURRENT=KEEP_IDLE_CURRENT
;
; INPUTS:
; Info: The main info block from SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
;-
PRO rrcat_stepper_reset_and_init, info, READ_VALUES=READ_VALUES, KEEP_IDLE_CURRENT=KEEP_IDLE_CURRENT
  default_idle_current = 300
  ;mocIndex = 4
  ;mocCurrent = 500
  ;mocSpeed = 200
  default_speed = 800
  default_accel = 16000
  default_current = 300
  default_microstep = 1

  speed    = default_speed
  accel    = default_accel
  current  = default_current


  stepper  = info.stepper
  retStr = stepper->reset()
  if keyword_set(debug) then message,retStr,/info
  retStr = stepper->setAsync()
  retStr = stepper->setSpeed(speed)
  ;retStr = stepper->setSpeed(mocSpeed, motor=mocIndex)
  retStr = stepper->setAccel(accel)
  retStr = stepper->setMotorCurrent(current)
  ;retStr = stepper->setMotorCurrent(mocCurrent, motor=mocIndex)
  IF KEYWORD_SET(KEEP_IDLE_CURRENT) THEN BEGIN
    retStr = stepper->setMotorCurrentIdle(default_idle_current)
  ENDIF ELSE BEGIN
    retStr = stepper->setMotorCurrentIdle(0)
  ENDELSE
  retStr = stepper->setMicroStep(default_microstep)

  if keyword_set(debug) then message,retStr,/info
  data = stepper->getStatus(nRetries=nRetries)
  if keyword_set(debug) then message, data, /info
  stepperMotors=info.stepperMotors
  foreach motorStr, stepperMotors, index do begin
    motorStr.minusEnabled = 1
    motorStr.plusEnabled = 1
    motorStr.async = 1
    motorStr.speed = default_speed
    ;IF index EQ mocIndex THEN motorStr.speed = mocSpeed
    motorStr.accel = default_accel
    motorStr.current = default_current
    ;IF index EQ mocIndex THEN motorStr.current = mocCurrent
    stepperMotors[index] = motorStr
  endforeach
  IF KEYWORD_SET(READ_VALUES) THEN BEGIN
    speed = info.speed_field_step->get_value()
    retStr = stepper->setSpeed(speed)
    stepperMotors[info.selected_motor_index].speed = speed
    accel = info.accel_field_step->get_value()
    retStr = stepper->setAccel(accel)
    stepperMotors[info.selected_motor_index].accel = accel
    current = info.current_field_step->get_value()
    retStr = stepper->setMotorCurrent(current)
    stepperMotors[info.selected_motor_index].current = current
  ENDIF
  info.stepperMotors = stepperMotors
END