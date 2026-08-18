;+
; NAME:
; RRCAT_SOLOIST_UPDATE_STEPPER_STATUS
;
; PURPOSE:
; This procedure updates the GUI stepper status fields.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_UPDATE_STEPPER_STATUS, info
;
; INPUTS:
; info:  the main info block structure.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018.
;   29 Aug 2019 (TRF): Removed tic()/toc() calls that were used to find cause of slowdown.
;-
PRO rrcat_soloist_update_stepper_status, info
  
;  IF info.debug THEN clock=tic('Stepper status')
  data = info.stepper->getStatus(nRetries=nRetries)
  str = rrcat_stepper_parse_string(data, info, /STATUS)
  ;if info.debug EQ 1 then SOLOIST_FTS_MESSAGE, info, str
;  IF info.debug THEN TOC,clock
  data = info.stepper->getMotorState(nRetries=nRetries)
  str = rrcat_stepper_parse_string(data, info, /MOTORSTATE)
;  IF info.debug THEN TOC,clock
  ;if info.debug EQ 1 then SOLOIST_FTS_MESSAGE, info, str
  data = info.stepper->getLimitState(nRetries=nRetries)
  str = rrcat_stepper_parse_string(data, info, /LIMITSTATE, /debug)
  ;if info.debug EQ 1 then SOLOIST_FTS_MESSAGE, info, str
;  IF info.debug THEN TOC,clock
  selected_motor = info.selected_motor
  selected_motor_index = info.selected_motor_index
  stepperMotors = info.stepperMotors
  WIDGET_CONTROL, info.stepper_pos_field, SET_VALUE = STRTRIM(stepperMotors[selected_motor_index].location, 2)
  WIDGET_CONTROL, info.stepper_status_field, SET_VALUE = rrcat_convert_step_status_to_string(stepperMotors[selected_motor_index].state)
  rrcat_soloist_fts_limit_status, info
;  IF info.debug THEN TOC,clock


END