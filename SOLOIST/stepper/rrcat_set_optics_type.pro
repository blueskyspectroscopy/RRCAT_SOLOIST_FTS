;+
; NAME:
; RRCAT_SET_OPTICS_TYPE
;
; PURPOSE:
; This procedure queries the stepper motors regarding the position
; of the optics flip mirror and if need be, calls the function to
; execute the move to the desired position.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SET_OPTICS_TYPE, info, opticsType
;
; INPUTS:
; info:  The main info structure.
; opticsType: The desired optics type.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;
;-
PRO rrcat_set_optics_type, info, opticsType
  SOLOIST_FTS_status,info,'Setting Optics type.'

   optics_position = rrcat_get_optics_position(info)
   wh = WHERE(STRUPCASE(optics_position) EQ STRUPCASE(opticsType), whCount)
   IF whCount GT 0 THEN RETURN
   
   SOLOIST_FTS_status,info,'Setting Optics position.'
   rrcat_set_optics_position, info, opticsType, steps=steps
   
   RETURN

END
