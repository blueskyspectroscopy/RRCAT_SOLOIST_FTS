;+
; NAME:
; RRCAT_SET_FTS_TYPE
;
; PURPOSE:
; This procedure queries the stepper motors regarding the position
; of the FTS flip mirror and if need be, calls the procedure that
; moves the mirror to the desired position.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; RRCAT_SET_FTS_TYPE, info, ftsType
;
; INPUTS:
; info:  The main info structure.
; ftsType: The desired FTS type.
;
; MODIFICATION HISTORY:
;   Written by: TRF, Mar 7 2018
;
;-
PRO rrcat_set_fts_type, info, ftsType
SOLOIST_FTS_status,info,'Setting FTS type.'
  fts_position = rrcat_get_fts_position(info)
  IF STRUPCASE(fts_position) EQ STRUPCASE(ftsType) THEN RETURN

  SOLOIST_FTS_status,info,'Setting FTS position.'
  rrcat_set_fts_position, info, ftsType, steps=steps

  RETURN

END
