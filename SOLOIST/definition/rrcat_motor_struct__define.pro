;+
; NAME:
; RRCAT_MOTOR_STRUCT__DEFINE
;
; PURPOSE:
; This is the structure definition for the RRCAT SOLOIST FTS stepper motors.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; info = {RRCAT_MOTOR_STRUCT__DEFINE}
;
; MODIFICATION HISTORY:
;   Written by: TRF, Feb 21 2018.
;-

pro RRCAT_MOTOR_STRUCT__DEFINE
  motor_struct = { RRCAT_MOTOR_STRUCT, $
    motor:0, $
    async:1, $
    state:0, $
    speed:0L, $
    accel:0L, $
    current:0L, $
    currentIdle:0L, $
    direction:0, $
    minusEnabled:1, $
    plusEnabled:1, $
    soft_hard_limit_minus:0, $
    soft_hard_limit_plus:0, $
    high_low_limit_minus:0, $
    high_low_limit_plus:0, $
    steps:0L, $
    location:0L, $
    windingsState:0, $
    windingsStateStop:0, $
    stepAction:0, $
    stepStyle:0, $
    limitminus:0, $
    limitplus:0, $
    latchminus:0, $
    latchplus:0, $
    fault:0 $
  }
end