;+
; NAME:
; RRCAT_SOLOIST_UPDATE_RELAY_FIELDS
;
; PURPOSE:
; This procedure modifies the queries the relay controller
; and updates the relay_status field in the RRCAT SOLOIST 
; info structure.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SOLOIST_UPDATE_RELAY_FIELDS, info
;
; INPUTS:
; info: The main info structure
;
; KEYWORDS:
;
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 26 2018.
;-
PRO RRCAT_SOLOIST_UPDATE_RELAY_FIELDS, info

  data = info.relay->relayStatus()
  ;print, data
  retVal = rrcat_parse_relay_string(data)
  IF retVal EQ '-1' THEN begin
    SOLOIST_FTS_MESSAGE,info,'Resetting Relay controller.'
    IF OBJ_VALID(info.relay) THEN BEGIN
      OBJ_DESTROY, info.relay
    ENDIF
    WIDGET_CONTROL, info.relay_port_field, GET_VALUE=relay_port
    relay = rrcat_soloist_init_relay(port=relay_port, baud=9600,data=8,parity='N',stop=1)
    info.relay=relay
  ENDIF
  ;print, retVal
  SOLOIST_FTS_MESSAGE,info,'Relay status:' + STRTRIM(retVal, 2)
  info.relay_status = retVal

END