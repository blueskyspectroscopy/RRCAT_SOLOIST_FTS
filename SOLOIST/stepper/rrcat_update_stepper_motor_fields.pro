;+
; NAME:
; RRCAT_SOLOIST_UPDATE_STEPPER_MOTOR_FIELDS
;
; PURPOSE:
; This procedure updates the GUI stepper fill-in fields for the currently-selected motor.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_UPDATE_STEPPER_MOTOR_FIELDS, motor_index, info
;
; INPUTS:
; motor_index: The index of the currently-selected motor.
; info:  the main info block structure.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018.
;-
PRO rrcat_update_stepper_motor_fields, motor_index, info
  stepperMotors = info.stepperMotors
  motorStr = stepperMotors[motor_index]
  info.speed_field_step->set_value, motorStr.speed
  info.accel_field_step->set_value, motorStr.accel
  info.current_field_step->set_value, motorStr.current
  ;info.current_idle_field_step->set_value, motorStr.currentIdle
  WIDGET_CONTROL, info.slew_dir_id_step, SET_VALUE=motorStr.direction
  ;WIDGET_CONTROL, info.async_bgroup_step, SET_VALUE=motorStr.async
;  WIDGET_CONTROL, info.enabled_minus_bgroup_step, SET_VALUE=motorStr.minusEnabled
;  WIDGET_CONTROL, info.soft_hard_limit_minus_bgroup_step, SET_VALUE=motorStr.soft_hard_limit_minus
;  WIDGET_CONTROL, info.limit_high_low_minus_bgroup_step, SET_VALUE=motorStr.soft_hard_limit_plus
;  WIDGET_CONTROL, info.enabled_plus_bgroup_step, SET_VALUE=motorStr.plusEnabled
;  WIDGET_CONTROL, info.soft_hard_limit_plus_bgroup_step, SET_VALUE=motorStr.high_low_limit_minus
;  WIDGET_CONTROL, info.limit_high_low_plus_bgroup_step, SET_VALUE=motorStr.high_low_limit_plus
  ;info.slew_steps_field_step->set_value, motorStr.steps
END