;+
; NAME:
; rrcat_soloist_init_relay
;
; PURPOSE:
; This function initializes the relay controller board for RRCAT.
; In addition to opening the communication port,
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; rrcat_soloist_init_relay
;
; INPUTS:
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 19 2018.
;-
function rrcat_soloist_init_relay, port=port,baud=baud,data=data,parity=parity,stop=stop,debug=debug

  if n_elements(baud) eq 0 then baud=9600 else baud=baud
  if n_elements(data) eq 0 then data=8 else data=data
  if n_elements(parity) eq 0 then parity='N' else parity=strtrim(parity,2)
  if n_elements(stop) eq 0 then stop=1 else stop=stop

  if n_elements(port) EQ 0 then begin

    b=widget_base(/col,title='SOLOIST_FTS Settings')
    x=fsc_inputfield(b,/StringValue,title='Enter Relay Controller Port:',xsize=6, value=relay_port)
    ok=widget_button(b,value='OK')
    widget_control,b,/real
    ev=widget_event(b,bad_id=bad)
    if (ev.id eq ok) and (bad eq 0) then begin
      relay_port = x->get_value()
      message,/info,'Relay Controller Port set to: '+relay_port
      widget_control,b,/dest
    endif
    port=relay_port
  endif else begin
    relay_port=port
  endelse
  
  relay=obj_new('kta223',port=relay_port,baud=baud,data=data,parity=parity,stop=stop)
  if not obj_valid(relay) then return, -1
  if keyword_set(debug) then message,'Relay Controller ready.',/info
  ;retVal = relay->keepAlive(0)

  return, relay

end