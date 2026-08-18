;+
; NAME:
; RRCAT_LIMIT_STRUCT__DEFINE
;
; PURPOSE:
; This is the structure definition for the RRCAT SOLOIST FTS stepper limits.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; info = {RRCAT_LIMIT_STRUCT__DEFINE}
;
; MODIFICATION HISTORY:
;   Written by: TRF, Feb 21 2018.
;-

pro RRCAT_LIMIT_STRUCT__DEFINE
  limit_struct = { RRCAT_LIMIT_STRUCT, $
    wminus:0, $
    wplus:0, $
    xminus:0, $
    xplus:0, $
    yminus:0, $
    yplus:0, $
    zminus:0, $
    zplus:0, $
    aminus:0, $
    aplus:0, $
    bminus:0, $
    bplus:0 $
  }
end