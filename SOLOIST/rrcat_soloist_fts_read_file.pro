;+
; NAME:
;	RRCAT_SOLOIST_FTS_READ_FILE
;
; PURPOSE:
;	This function reads the interferogram files written by RRCAT_SOLOIST_FTS.pro. Compile and
;	run the example procedure at the bottom of the file for usage examples.
;
; CATEGORY:
;	FTS
;
; CALLING SEQUENCE:
;	Result = RRCAT_SOLOIST_FTS_READ_FILE(File)
;
; INPUTS:
;	File: the full pathname of the file to open. If a null string is given,
;	or if no parameter is given, then a file selection dialog will appear.
;
; KEYWORD PARAMETERS:
;	None.
;
;	OUTPUTS:
;	This function returns a strucure containing the infoblock and data arrays.
;	The structure has the form: {header:{RRCAT_SOLOIST_FTS_HEADER}, opd:FLTARR(n), signal:FLTARR(n)}
;	where n is the number of samples given by result.header.samples
;	If an error occurs, then the returned value will be -1 instead of a structure
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, January, 2018.
; 	Based on SOLOIST_FTS_READ_FILE
;
;-

function RRCAT_SOLOIST_FTS_READ_FILE, file, header=header, parent=parent

;----------------------------------
	if n_elements(file) eq 0 then file='' else file=strlowcase(file)

	if file eq '' then begin
		file=dialog_pickfile(/read,filter=['*.ifg'],/fix_filter,$
			title='Please select a SOLOIST_FTS data file to read...')
		if file eq '' then return,0 else file=strlowcase(file)
		endif

	err=0
	OPENR, lun, file, /GET_LUN, error=err

	CATCH, error
	IF error NE 0 THEN BEGIN
		Result = DIALOG_MESSAGE( ['There has been a fatal error reading file '+file+':',$
			!ERROR_STATE.MSG,'Check the message window for errors.'], $
			/ERROR, /center, dialog_parent=parent ,TITLE='SOLOIST_FTS_READ_FILE Error' )
		if n_elements(lun) ne 0 then free_lun,lun
;		CATCH, /CANCEL	;is this necessary?
		return,-1
	ENDIF

	; If err is nonzero, something happened opening the file
	IF (err NE 0) then begin
		Result = DIALOG_MESSAGE( ['Error trying to open the file '+file+':',$
			!ERROR_STATE.MSG,'Check the message window for errors.'], $
			/ERROR, /center, dialog_parent=parent ,TITLE='SOLOIST_FTS_READ_FILE Error' )
		if n_elements(lun) ne 0 then free_lun,lun
		return,-1
		endif

	header={rrcat_soloist_fts_header}
	READU, lun, header

	case header.version of
		2.0 : begin
			opd = fltarr(header.samples)
			signal = opd
			READU, lun, opd, signal

			FREE_LUN, lun
			return,{header:header,opd:opd,signal:signal}
			end
		; insert subsequent version numbers here, and assign the appropriate infoblock structure
		else: begin
			message,'There has been a fatal error reading file '+file+': The file version is unrecognized.',/cont
			free_lun,lun
			return,-1
			endelse
		endcase

END

