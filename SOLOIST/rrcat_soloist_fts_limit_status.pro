
;+
; NAME:
; rrcat_soloist_fts_limit_status
;
;
; PURPOSE:
;	This procedure reads the limit status from the info structure and
;	updates the display table in the GUI.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	rrcat_soloist_fts_limit_status, Info
;
; INPUTS:
;	Info:	The main info block.
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, May 24 2018. Based on SOLOIST_FTS_DRIVE_STATUS
;-


pro rrcat_soloist_fts_limit_status, info

  stepperMotors = info.stepperMotors
  limitMinus = stepperMotors.limitMinus
  limitPlus = stepperMotors.limitPlus

  ;Limit status bitmask
  ;	*	0	W Limit -			*
  ;	*	1	W Limit +			*
  ;	*	2	X Limit -			*
  ;	*	3	X Limit +			*
  ;	*	4	Y Limit -			*
  ;	*	5	Y Limit +			*
  ;	*	6	A Limit -  		*
  ;	*	7	A Limit +			*
  ;	*	8	B Limit -			*
  ;	*	9	B Limit +			*

  limitVals = intarr(10)
  limitVals[0:*:2]=limitMinus
  limitVals[1:*:2]=limitPlus

  inds=where(limitVals,count)
  colors=bytarr(3,n_elements(limitVals))
  colors[0,*]=255

  if count gt 0 then begin
    colors[0,inds]=0
    colors[1,inds]=255
  endif

  widget_control,info.limit_status_id_stepper,background_color=colors

end



