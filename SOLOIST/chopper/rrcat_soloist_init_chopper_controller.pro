;+
; NAME:
; rrcat_soloist_init_chopper_controller
;
; PURPOSE:
; This function initializes the chopper controller for RRCAT.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_soloist_init_chopper_controller
;
; INPUTS:
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 19 2018.
;-
function rrcat_soloist_init_chopper_controller, port=port,baud=baud,data=data,parity=parity,stop=stop,debug=debug

  if n_elements(baud) eq 0 then baud=115200 else baud=baud
  if n_elements(data) eq 0 then data=8 else data=data
  if n_elements(parity) eq 0 then parity='N' else parity=strtrim(parity,2)
  if n_elements(stop) eq 0 then stop=1 else stop=stop

  if n_elements(port) EQ 0 then begin
    b=widget_base(/col,title='SOLOIST_FTS Settings')
    x=fsc_inputfield(b,/StringValue,title='Enter Chopper Controller Port:',xsize=6, value=chopper_port)
    ok=widget_button(b,value='OK')
    widget_control,b,/real
    ev=widget_event(b,bad_id=bad)
    if (ev.id eq ok) and (bad eq 0) then begin
      chopper_port = x->get_value()
      message,/info,'Chopper Controller Port set to: '+chopper_port
      widget_control,b,/dest
    endif
    port=chopper_port
  endif else begin
    chopper_port = port
  endelse
  chopper=obj_new('MC2000B',port=chopper_port,baud=baud,data=data,parity=parity,stop=stop)
  if not obj_valid(chopper) then return, chopper
  if keyword_set(debug) then message,'Chopper Controller ready.',/info


  return, chopper

end