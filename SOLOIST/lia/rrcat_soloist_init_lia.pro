;+
; NAME:
; rrcat_soloist_init_lia
;
; PURPOSE:
; This function initializes the lock-in amplifier for RRCAT.
;
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_soloist_init_lia
;
; INPUTS:
;
; MODIFICATION HISTORY:
;   Written by: TRF, Jun 05 2018.
;-
function rrcat_soloist_init_lia,port=port,baud=baud,data=data,parity=parity,stop=stop,debug=debug

  if n_elements(baud) eq 0 then baud=9600 else baud=baud
  if n_elements(data) eq 0 then data=8 else data=data
  if n_elements(parity) eq 0 then parity='N' else parity=strtrim(parity,2)
  if n_elements(stop) eq 0 then stop=1 else stop=stop

  if n_elements(port) eq 0 then begin
    b=widget_base(/col,title='SOLOIST_FTS Settings')
    x=fsc_inputfield(b,/StringValue,title='Enter Lock-in Amplifier Port:',xsize=6, value=lia_port)
    ok=widget_button(b,value='OK')
    widget_control,b,/real
    ev=widget_event(b,bad_id=bad)
    if (ev.id eq ok) and (bad eq 0) then begin
      lia_port = x->get_value()
      message,/info,'Lock-in Amplifier Port set to: '+lia_port
      widget_control,b,/dest
    endif
    port=lia_port
  endif else begin
    lia_port=port
  endelse

  lia=obj_new('SR830',port=lia_port,baud=baud,data=data,parity=parity,stop=stop)
  if not obj_valid(lia) then return, lia
  n_bytes=lia->command('REST')
  IF n_bytes EQ -1 THEN BEGIN
    obj_destroy, lia
    return, lia
  ENDIF
  if keyword_set(debug) then message,'Lock-in Amplifier ready.',/info

  return, lia

end