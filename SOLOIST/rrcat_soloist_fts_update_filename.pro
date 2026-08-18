;+
; NAME:
;	RRCAT_SOLOIST_FTS_update_filename
;
; PURPOSE:
;	This procedure reads the current file number, date, and prefix and
;	assembles a filename. The filename field is updated.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_update_filename, Info
;
; INPUTS:
;	Info:	The main infoblock from SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
;   Adapted from SOLOIST_FTS_update_filename.pro
; 	Written by:	Trevor Fulton, 20 Dec 2017.
; 	
; 	17 May 2018 (TRF): Added optics and detector to filename
;
;-

pro RRCAT_SOLOIST_FTS_update_filename,info
  id=widget_info(info.tlb,find_by_uname='filename')
  meas_type = info.measurement_type
  optics_type = info.optics
  det_type = info.det_type
  prefix=info.prefix_field->get_value()
  CALDAT, systime(/julian), Month, Day, Year
  date=string(year-2000,month,day,format='(I2.2,I2.2,I2.2)')
  number=info.number_field->get_value()
  info.filename=meas_type+'_'+optics_type+'_'+det_type+'_'+prefix+'_'+date+'_'+string(number,format='(I4.4)')+'.ifg'
  widget_control,id,set_value=info.filename
  return
end
