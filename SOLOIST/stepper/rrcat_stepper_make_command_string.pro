;+
; NAME:
; rrcat_stepper_make_command_string
;
; PURPOSE:
; This function takes the information in the rrcat_motor_struct
; argument and makes a string that is used to send a command
; to the stepper motor controller.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; retStr = rrcat_stepper_make_command_string(stepperMotorStruct)
; 
; INPUTS:
; stepperMotorStruct: rrcat motor structure that contains the values of
; the limits to be set.
; 
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 13 2018.
;-
FUNCTION rrcat_stepper_make_command_string, stepperMotorStruct
   retVal = 1024+64
   IF stepperMotorStruct.minusEnabled EQ 0 THEN retVal = retVal + 4
   IF stepperMotorStruct.plusEnabled EQ 0 THEN retVal = retVal + 32

   IF stepperMotorStruct.high_low_limit_minus EQ 1 THEN retVal = retVal + 1
   IF stepperMotorStruct.soft_hard_limit_minus EQ 1 THEN retVal = retVal + 2

   IF stepperMotorStruct.high_low_limit_plus EQ 1 THEN retVal = retVal + 8
   IF stepperMotorStruct.soft_hard_limit_plus EQ 1 THEN retVal = retVal + 16
   
   retStr = STRTRIM(retVal, 2) + 'T'
   return, retStr
END