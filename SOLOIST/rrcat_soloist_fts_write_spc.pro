;+
; NAME:
;	RRCAT_SOLOIST_FTS_WRITE_SPC
;
; PURPOSE:
;	This procedure writes the current spectrum to a file.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_WRITE_SPC, Info
;
; INPUTS:
;	Info:	The main infoblock from SOLOIST_FTS.pro
;
; KEYWORD PARAMETERS:
;	AVG:	Set this keyword to write the average spectrum instead of the current one.
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Jul 10 2009.
; 	Dec 14 2017 (TRF) Modified for RRCAT. Added housekeeping and configuration to header of file.
;-

pro RRCAT_SOLOIST_FTS_WRITE_SPC,info,avg=avg


	n=info.scans_field->get_value()
	if keyword_set(avg) then avg_text='_avg_'+strtrim(n,2) else avg_text=''

	file=info.directory+file_basename(info.filename,'.ifg')+avg_text+'.spc'

	if file_test(file) then begin ;the file already exists
    STOP
		result=dialog_message(['The file '+file+' already exists!','Overwrite?'],$
			/question, /default_no, title='File Error', dialog_parent=info.tlb)
		if result eq 'No' then begin
prompt:
			file=dialog_pickfile(dialog_parent=info.tlb, file=file, /write, $
				title='Select a new filename...')
			if file eq '' then return
			endif else begin	;overwrite the file
			info.directory=file_dirname(file)+path_sep()
			info.filename=file_basename(file)
			endelse
		endif


	if keyword_set(avg) then begin
;		data=info.spc_plot->getData('avg')
    if n_elements(*info.avg_spc) gt 0 then data=abs(*info.avg_spc) 
		endif else begin
;		data=info.spc_plot->getData('current')
    if n_elements(*info.spc) gt 0 then data=abs(*info.spc)
		endelse

	if n_elements(data) lt 2 then begin
		 SOLOIST_FTS_status,info, 'No data to write.'
		 return
		endif


	header = {rrcat_soloist_fts_header}

	header.version = 2.0
	prefix=byte(strmid(info.prefix_field->get_value(),0,12)) ;make sure there are no more than 12 characters
	header.file_prefix[0:n_elements(prefix)-1] = prefix	;write to field with terminating null(s)
	header.measurement_type = byte(strmid(info.measurement_type,0,23))
	header.fts_type = byte(strmid(info.fts_type,0,23))
	header.det_type = byte(strmid(info.det_type,0,23))
	header.optics = byte(strmid(info.optics,0,23))
	header.fts_temp_1=info.housekeeping.fts_temp_1
	header.fts_temp_2=info.housekeeping.fts_temp_2
	header.fts_pressure=info.housekeeping.fts_pressure
;	header.det_temp_1=info.housekeeping.det_temp_1
;	header.det_temp_2=info.housekeeping.det_temp_2
;	header.det_temp_3=info.housekeeping.det_temp_3
	header.det_pressure=info.housekeeping.det_pressure
	header.file_number = info.number_field->get_value()
	header.num_scans = info.scans_field->get_value()
	header.current_scan = header.num_scans - info.scans_remaining
	header.resolution = info.resolution_field->get_value()

	text=widget_info(info.nyquist_id,/combobox_gettext)
	result=min(abs(float(text)-(*info.nyquist_list)),ind)
	header.nyquist=(*info.nyquist_list)[ind]

	header.samples = n_elements(data)
	header.speed = info.speed_field->get_Value()
	header.zpd = info.zpd
	header.buffer_size = info.buffer

	header.date = byte(systime())
	header.juldate = systime(/jul)
	source=byte(strmid(info.source_field->get_value(),0,80)) ;make sure there are no more than 80 characters
	header.source[0:n_elements(source)-1] = source	;write to field with terminating null(s)
	comment=byte(strmid(info.comment_field->get_value(),0,80)) ;make sure there are no more than 80 characters
	header.comment[0:n_elements(comment)-1] = comment	;write to field with terminating null(s)

  IF info.debug THEN SOLOIST_FTS_MESSAGE,info,'Writing spectrum to: '+file
	WRITE_SPC,file,data,(*info.wn)[0],(*info.wn)[1]-(*info.wn)[0], header=header, source=header.source, comment=header.comment

end