
;+
; NAME:
;	RRCAT_SOLOIST_FTS_SAVE_SETTINGS
;
; PURPOSE:
;	This procedure saves some of the important program settings to a file
;	so that the program state can be restored in the next session.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_SAVE_SETTINGS, Info
;
; INPUTS:
;	Info:	The main infoblock from SOLOIST_FTS.pro
;	File: The filepath to save the settings in. Defaults to soloist_fts_settings.var
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Jan 8 2018. Based on SOLOIST_FTS_SAVE_SETTINGS.pro
; 	31 Jul 2019 (TRF): Added hk_refresh.
;-

pro RRCAT_SOLOIST_FTS_save_settings,info,file

   ; Establish error handler. When errors occur, the index of the
   ; error is returned in the variable Error_status:
   CATCH, Error_status
   ;This statement begins the error handler:
   IF Error_status NE 0 THEN BEGIN
      ;using the continue keyword will output the error to the journal but not stop processing.
      msg=!ERROR_STATE.MSG
      message, 'Error index: '+ strtrim(Error_status,2),/cont 
      message, 'Error message: '+ msg,/cont 
      CATCH, /CANCEL
      return
   ENDIF

	settings={$
		FTS_TYPE:'',$
    SOLOIST_TYPE:'',$
		ADC_MODEL:'',$
		ADC_IP:'',$
		MC1808X_serial:'',$
		buffer:0.,$
		gain:0,$
		ip:'',$
		port:0L,$
		directory:'',$
		prefix:'',$
		number:0l,$
		comment:'',$
		source:'',$
		speed:0.,$
		acceleration:0.,$
		start_delay:0.,$
		home_speed:0.,$
		resolution:0.,$
		double_sidedness:0.,$
		symmetrical:0,$
		nyquist:0.,$
		sampling:0l,$
		fts_metrology:'',$
		det_type:'',$
		optics_type:'',$
		zpd:0.,$
		zpd_lw:0.,$
		zpd_sw:-0.0666,$
		det_samples:0.,$
		max_travel:0.,$
		min_travel:0.,$
		pso_zero_position:0.,$
		encoder:'',$
		freq_resp:0.,$
		max_freq:0.,$
		scans:0l,$
		xsize:0l,$
		ysize:0l,$
		autoscale_spc:0,$
		autoscale_ifg_x:0,$
    autoscale_ifg_y:0,$
		ylog:0, $
		clock_source:0B, $
		clock_freq:0,$
		fts_selected:'',$
		hk_refresh:0.}

	geo=widget_info(info.tlb,/geometry)
	settings.xsize=geo.xsize
	settings.ysize=geo.ysize

	settings.soloist_type=info.soloist_type
	settings.fts_type=info.fts_type
	settings.fts_selected=info.fts_selected
	settings.ADC_MODEL=info.adc_model
	settings.MC1808X_serial=info.MC1808X_serial
	settings.ADC_IP=info.ADC_IP
	settings.buffer=info.buffer
	settings.gain=info.gain
	settings.ip = info.ip
	settings.port = info.port
	settings.directory=info.directory
	settings.prefix=info.prefix_field->get_value()
	settings.number=info.number_field->get_value()
	settings.comment=info.comment_field->get_value()
	settings.source=info.source_field->get_value()
	settings.speed=info.speed_field->get_value()
	settings.acceleration=info.acceleration
	settings.start_delay=info.start_delay
	settings.home_speed=info.home_speed
	settings.resolution=info.resolution_field->get_value()
	
  speed = info.speed_field->get_value()
  case info.freq_units of
    'ghz':settings.resolution=ghz2wn(settings.resolution)
    'wn':
    'hz':settings.resolution=settings.resolution/speed
    else:message,'Unhandled frequency units!',/cont
  endcase

	settings.double_sidedness=info.ds_field->get_value()
	settings.symmetrical=info.symmetrical

	settings.nyquist=SOLOIST_FTS_GET_NYQUIST(info)

	settings.zpd=info.zpd
	settings.zpd_lw=info.zpd_lw
	settings.zpd_sw=info.zpd_sw
	settings.det_samples=info.det_samples
	settings.max_travel=info.max_travel
	settings.min_travel=info.min_travel
	settings.encoder=info.encoder
	settings.pso_zero_position=info.pso_zero_position
	
	settings.fts_metrology=info.fts_metrology
	settings.det_type=info.det_type
	settings.optics_type=info.optics
	
	settings.scans=info.scans_field->get_value()
	settings.freq_resp=info.freq_resp
	settings.max_freq=info.max_freq  ;max_freq is always in wavenumbers
	settings.autoscale_spc=info.autoscale_spc
	settings.autoscale_ifg_x=info.autoscale_ifg_x
  settings.autoscale_ifg_y=info.autoscale_ifg_y

	info.spc_plot->getAxisProperty,ylog=ylog
	settings.ylog=ylog


	settings.clock_source=info.clock_source
	settings.clock_freq=info.clock_freq
	settings.hk_refresh=info.hk_refresh

;  if n_elements(file) eq 0 then filename=ProgramRootDir()+'soloist_fts_settings.var' $
;    else filename=file
;  save,settings,filename=filename

  if n_elements(file) eq 0 then filename=ProgramRootDir()+'rrcat_soloist_fts_settings.xml' $
    else filename=file
  

  if float(!version.release) ge 8.3 then begin
    settings_hash=XML_hash(settings)
    !null = settings_hash.ToXml(string=xml_str)
  endif else begin
    ;this works for IDL 8.2 where the orderedhash object doesn't exist.
    obj=obj_new('XML_hash_82',settings)
    !null = obj->ToXml(string=xml_str)
  endelse
  if info.debug THEN BEGIN
    ;SOLOIST_FTS_MESSAGE, info, 'Saving settings to: '+filename
  endif
  openw,lun,filename,/get
  
  printf,lun,xml_str
  free_lun,lun

end

