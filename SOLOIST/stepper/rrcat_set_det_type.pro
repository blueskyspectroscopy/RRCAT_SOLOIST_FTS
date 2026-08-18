;+
; NAME:
; RRCAT_SET_DET_TYPE
;
; PURPOSE:
; This procedure checks whether the detector flip mirror needs to be moved
; to the selected detector position and if so, calls the procedure to 
; execute that move.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SET_DET_TYPE, info, opticsType, detType
;
; INPUTS:
; info:  The main info structure.
; opticsType: The selected optics type.
; detType: The selected detector.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;-
PRO rrcat_set_det_type, info, opticsType, detType
  SOLOIST_FTS_status,info,'Setting Detector type.'

  detPosition = rrcat_get_det_position(info, opticsType)
  wh = WHERE(STRUPCASE(detPosition) EQ STRUPCASE(detType), whCount)
  IF whCount GT 0 THEN RETURN
  SOLOIST_FTS_status,info,'Setting Detector position.'

  rrcat_set_det_position, info, opticsType, detType, steps=steps

  RETURN

END
