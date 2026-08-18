;+
; NAME:
; rrcat_soloist_init_stepper_controller
;
; PURPOSE:
; This function initializes the stepper controller board for RRCAT.
; In addition to opening the communication port, this function also
; sets the default stepper speed, acceleration, and motor current
; values.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_soloist_init_stepper_controller
;
; INPUTS:
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 1 2018.
;-
function rrcat_soloist_init_stepper_controller, stepperMotors=stepperMotors, port=port,baud=baud,data=data,parity=parity,stop=stop,debug=debug

  if n_elements(baud) eq 0 then baud=9600 else baud=baud
  if n_elements(data) eq 0 then data=8 else data=data
  if n_elements(parity) eq 0 then parity='N' else parity=strtrim(parity,2)
  if n_elements(stop) eq 0 then stop=1 else stop=stop

  if n_elements(port) eq 0 then begin
    b=widget_base(/col,title='SOLOIST_FTS Settings')
    x=fsc_inputfield(b,/StringValue,title='Enter Stepper Controller Port:',xsize=6, value=stepper_port)
    ok=widget_button(b,value='OK')
    widget_control,b,/real
    ev=widget_event(b,bad_id=bad)
    if (ev.id eq ok) and (bad eq 0) then begin
      stepper_port = x->get_value()
      message,/info,'Stepper Controller Port set to: '+stepper_port
      widget_control,b,/dest
    endif
    port=stepper_port
  endif else begin
    stepper_port=port
  endelse
  stepper=obj_new('BC6D20',port=stepper_port,baud=baud,data=data,parity=parity,stop=stop)
  if not obj_valid(stepper) then return, stepper
  if keyword_set(debug) then message,'Stepper Controller ready.',/info

  default_speed = 800
  default_accel = 16000
  default_current = 300
  default_microstep = 1

  ;
  ; Set these values for all motors
  ;
  retStr = stepper->reset()
  if keyword_set(debug) then message,retStr,/info
  retStr = stepper->setAsync()
  retStr = stepper->setSpeed(default_speed)
  retStr = stepper->setAccel(default_accel)
  retStr = stepper->setMotorCurrent(default_current)
  retStr = stepper->setMotorCurrentIdle(0)
  retStr = stepper->setMicroStep(default_microstep)
  if keyword_set(debug) then message,retStr,/info
  data = stepper->getStatus(nRetries=nRetries)
  if keyword_set(debug) then message, data, /info
  IF KEYWORD_SET(stepperMotors) THEN BEGIN
    foreach motorStr, stepperMotors, index do begin
      motorStr.minusEnabled = 1
      motorStr.plusEnabled = 1
      motorStr.async = 1
      motorStr.speed = default_speed
      motorStr.accel = default_accel
      motorStr.current = default_current
      stepperMotors[index] = motorStr
    endforeach
  ENDIF
  return, stepper

end