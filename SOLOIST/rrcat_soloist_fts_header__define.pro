;+
; NAME:
;	RRCAT_SOLOIST_FTS_HEADER__DEFINE
;
; PURPOSE:
;	This is the structure definition for the SOLOIST FTS file header.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	info = {RRCAT_SOLOIST_FTS_HEADER}
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
; 	Dec 14 2017 (TRF) Modified for RRCAT. Added housekeeping and configuration to header.
;-

pro RRCAT_SOLOIST_FTS_HEADER__DEFINE

; -------  371 bytes total  -----------

	header_block = { rrcat_soloist_fts_header, $
; -------  File Version  ---------- 4 bytes
	   			version:0., $		;This version is 2.0 (new Soloist controller version)
; -------  FTS PARAMETERS  ---------- 49+72+28 bytes
				file_prefix:BYTARR(13), $	;12 characters plus a terminating null
				measurement_type:BYTARR(24), $
   		  fts_type:BYTARR(24), $
   		  det_type:BYTARR(24), $
   		  optics:BYTARR(24), $
   		  fts_temp_1:0.,$
   		  fts_temp_2:0.,$
   		  fts_pressure:0.,$
;   		  det_temp_1:0.,$
;   		  det_temp_2:0.,$
;   		  det_temp_3:0.,$
   		  det_pressure:0.,$
				file_number:0L, $
				num_scans:0L, $
				current_scan:0L, $
				resolution:0., $
				nyquist:0., $
				samples:0L,$
				speed:0., $
				zpd:0.,$		;ZPD location in mm MPD
				buffer_size:0L,$
; -------  OBSERVATION PARAMETERS  ---------- 194 bytes
				date:BYTARR(24), $	;date and time string
				juldate:0d, $	;Julian date
				source:BYTARR(81), $	;80 chars plus a terminating null
				comment:BYTARR(81) $
				}



end