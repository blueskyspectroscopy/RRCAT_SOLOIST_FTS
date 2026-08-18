;+
; NAME:
;	RRCAT_SOLOIST_FTS_KILL
;
; PURPOSE:
;	This is the widget kill notification event handler, called when the program exits.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_KILL, Id
;
; INPUTS:
;	Id:	The widget ID for the main base.
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, Mar 7 2018. Based on SOLOIST_FTS_KILL
;-

pro RRCAT_SOLOIST_FTS_KILL, id

  catch, error
  if error ne 0 then begin
    message,'Error occured during shutdown.',/cont
    message,strmessage(error),/cont
    return
  endif

  widget_control,id,get_uvalue=info

  if info.simADC eq 0 then result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)

  if info.simStage eq 0 then begin
    result=info.soloist->abort(err=err)
    result=info.soloist->disable()
    result=info.soloist->close()
  endif

  if info.simStepper eq 0 then begin
    result=info.stepper->close()
  endif

  if info.simChopper eq 0 then begin
    result=info.chopper->close()
  endif

  if info.simRelay eq 0 then begin
    result=info.relay->close()
  endif

  if info.simLia eq 0 then begin
    result=info.lia->close()
  endif

  if ptr_valid(info.opd) then ptr_free,info.opd

  if ptr_valid(info.simData) then ptr_free,info.simData

  PROFILER, /REPORT, output=prof
  print,info,prof
  if info.debug then begin
    if !journal ne 0 then journal	;if a journal file is open, close it
  endif
  
end
