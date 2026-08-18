;+
; NAME:
; rrcat_soloist_relay_state
;
; PURPOSE:
; This function changes the vector returned by the RRCAT SOLOIST
; GUI element used to select the relays into a single number
; that is used to command the relay controller.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; struct = rrcat_soloist_relay_state(info, relay_state)
;
; INPUTS:
; info: The RRCAT SOLOIST info structure
; relay_state: The vector returned by the GUI selection element.
;
; KEYWORDS:
;
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 26 2018.
;-
FUNCTION rrcat_soloist_relay_state, info, relay_status

  relay_state = $
    relay_status[0] + $
    relay_status[1]*2 + $   
    relay_status[2]*4 + $
    relay_status[3]*8 + $
    relay_status[4]*16 + $
    relay_status[5]*32 + $
    relay_status[6]*64; + $
;    relay_status[7]*128
    
  return, relay_state
END