;+
; NAME:
; RRCAT_GET_MOTOR_STRING
;
; PURPOSE:
; This function translates the motor index into a string number
; that is then used to issue a command to the stepper motor 
; controller.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_GET_MOTOR_STRING, motor
;
; INPUTS:
; motor: The index of the motor.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018.
;-
function rrcat_get_motor_string, motor
  CASE MOTOR OF
    0: BEGIN
      motorStr = '1'
    END
    1: BEGIN
      motorStr = '2'
    END
    2: BEGIN
      motorStr = '3'
    END
    3: BEGIN
      motorStr = '4'
    END
    4: BEGIN
      motorStr = '5'
    END
    5: BEGIN
      motorStr = '6'
    END
    ELSE: BEGIN
      print, "Invalid motor selected"
      STOP
    END
  ENDCASE
  RETURN, motorStr
END
