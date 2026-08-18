;+
; NAME:
;	RRCAT_SOLOIST_FTS_load_settings
;
; PURPOSE:
;	This procedure is used to restore the program settings that were
;	saved by RRCAT_SOLOIST_FTS_SAVE_SETTINGS.pro.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=RRCAT_SOLOIST_FTS_load_settings(Info,File)
;
; INPUTS:
;	Info:	The main info block from SOLOIST_FTS.pro
;	File: A file pathname to load. Defaults to soloist_fts_settings.var
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
;   Apr 11 2014 (BGG) - changed to use XML
;   Aug 29 2017 (BGG) - changed to function to return error status
;   30 Jul 2019 (TRF): Checks to see if info.directory exists and if it does not, create it
;   31 Jul 2019 (TRF): Added hk_refresh
;-



function RRCAT_SOLOIST_FTS_load_settings,info,file

  ; Establish error handler
  CATCH, Error_status
  IF Error_status NE 0 THEN BEGIN
    ;using the continue keyword will output the error to the journal but not stop processing.
    msg=!ERROR_STATE.MSG
    soloist_fts_message, info, 'Error loading settings!'
    soloist_fts_message, info, msg
    CATCH, /CANCEL
    return,0
  ENDIF

  if n_elements(file) eq 0 then	filename = Filepath(Root_Dir=ProgramRootDir(), 'rrcat_soloist_fts_settings.xml') $
  else filename=file
  if info.debug THEN BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Loading settings from: '+filename
  endif

  if file_test(filename,/regular,/read) eq 0 then begin
    if n_elements(file) ne 0 then begin ;filename was given, but it doesn't exist
      soloist_fts_message, info, 'Could not open settings file!'
      return,0
    endif
    ;default file doesn't exist, use default values
    settings=hash({$
      FTS_TYPE:'Michelson',$
      SOLOIST_TYPE:'ML',$
      ADC_MODEL:'DT9804',$
      ADC_IP:'',$
      MC1808X_serial:'',$
      buffer:0.,$
      gain:1,$
      ip:'10.28.1.41',$
      port:8000L,$
      prefix:'soloist_fts',$
      directory:'c:\rrcat_soloist_fts\',$
      number:0l,$
      comment:'',$
      source:'',$
      speed:1.0,$	;cm/s opd			v=f/nyq
      acceleration:100,$ ;mm/s^2 mechanical
      start_delay:0.,$   ;seconds
      home_speed:20,$  ;mm/s mechanical
      resolution:0.1,$	;cm-1			dv=1.21/(2*opdmax)
      double_sidedness:1.0,$  ;cm-1
      symmetrical:0,$
      nyquist:50.,$	;cm-1
      ;				sampling:100,$	;cm opd		dz<= 1/(2*nyq)
      zpd:0.,$		;default ZPD location (in mm MPD)
      max_travel:0.,$
      min_travel:0.,$
      pso_zero_position:0.,$
      encoder:'MXH',$
      freq_resp:50.,$
      max_freq:2500.,$	;maximum frequency of interest (cm-1)
      scans:1l,$
      xsize:1000,$
      ysize:600,$
      autoscale_spc:1,$	;default to autoscaling the spectral plot
      autoscale_ifg_x:1,$	;default to autoscaling the interferogram x axis
      autoscale_ifg_y:1,$ ;default to not autoscaling the interferogram y axis
      ylog:1, $ ;default to log spectral scale
      clock_source:0B, $
      clock_freq:0,$
      hk_refresh:300.,$
      fts_selected:'Martin-Puplett'})
  endif else begin
    ;filename was found
    ;restore,filename
    openr,lun,filename,/get
    ; Read one line at a time, saving the result into one long string
    str = ''
    line = ''
    WHILE NOT EOF(lun) DO BEGIN
      READF, lun, line
      str = str+line
    ENDWHILE

    if float(!version.release) ge 8.3 then begin
      settings = XML_hash.FromXML(string=str)
    endif else begin
      ;this works for IDL 8.2 where the orderedhash object doesn't exist.
      obj=obj_new('XML_hash_82')
      settings = obj->FromXml(string=str)
    endelse

    ; Close the file and free the file unit
    FREE_LUN, lun
  endelse

  info.fts_type=settings['FTS_TYPE']
  info.fts_selected=settings['FTS_SELECTED']
  info.soloist_type=settings['SOLOIST_TYPE']
  info.adc_model=settings['ADC_MODEL']
  info.adc_ip=settings['ADC_IP']
  info.mc1808x_serial=settings['MC1808X_SERIAL']
  info.buffer=settings['BUFFER']
  info.gain=settings['GAIN']
  info.ip=settings['IP']
  info.port=settings['PORT']
  info.directory=settings['DIRECTORY']
  IF FILE_TEST(info.directory) NE 1 THEN BEGIN
    FILE_MKDIR, info.directory
  ENDIF
  info.prefix_field->set_value,settings['PREFIX']
  info.number_field->set_value,settings['NUMBER']
  info.comment_field->set_value,settings['COMMENT']
  info.source_field->set_value,settings['SOURCE']
  info.speed_field->set_value,settings['SPEED']
  info.ds_field->set_value,settings['DOUBLE_SIDEDNESS'],/float
  info.symmetrical=settings['SYMMETRICAL']
  widget_control,info.sym_button,set_value=info.symmetrical
  info.ds_field->setProperty,sensitive=~info.symmetrical

  ;do not load in the freq_units parameter to avoid having to reset all the plots, fields, etc
  ;info.freq_units=settings['FREQ_UNITS']

  speed = info.speed_field->get_value()
  case info.freq_units of
    'ghz':info.resolution_field->set_value,wn2ghz(settings['RESOLUTION'])
    'wn':info.resolution_field->set_value,settings['RESOLUTION']
    'hz':info.resolution_field->set_value,settings['RESOLUTION']*speed
    else:message,'Unhandled frequency units!',/cont
  endcase

  ;Moved the nyquist list setting to SOLOIST_FTS_SET_NYQUIST_LIST
  ;	;update the nyquist field for the type of FTS
  ;	sampling=reverse((findgen(1000)+1)/1000)	;valid PSO intervals in mm. Minimum interval is 1um
  ;							;sampling=[sampling,0.0015,0.0025,0.0035]
  ;							;sampling=reverse(sampling[sort(sampling)])
  ;
  ;	Case info.FTS_TYPE of
  ;		'MZ':nyquist=1./(8.*sampling/10.)	;for MZ FTS
  ;		else: nyquist=1./(4.*sampling/10.)  ;for Michelson
  ;		endcase
  ;;	inds=where((nyquist le 1000.) and (nyquist ge 10))	;useful Nyquist values
  ;	inds=where(nyquist ge 20)	;useful Nyquist values
  ;
  ;	sampling_list=sampling[inds]
  ;	nyquist_list=nyquist[inds]
  ;	if info.freq_units eq 'ghz' then begin
  ;    widget_control,info.nyquist_id,set_value=string(wn2ghz(nyquist_list),format='(f8.2)')
  ;    endif else begin
  ;    widget_control,info.nyquist_id,set_value=string(nyquist_list,format='(f7.2)')
  ;    endelse
  ;	*info.nyquist_list=nyquist_list
  ;	*info.sampling_list=sampling_list
  
  info.fts_metrology=settings['FTS_METROLOGY']
  IF info.fts_metrology EQ 'PSO' THEN BEGIN
    *info.nyquist_list=*info.nyquist_list_pso
    *info.sampling_list=*info.sampling_list_pso
  ENDIF ELSE BEGIN
    *info.nyquist_list=*info.nyquist_list_laser
    *info.sampling_list=*info.sampling_list_laser
  ENDELSE
  RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST,info

  ;change the nyquist selection to the closest match to the settings value.
  result=min(abs(settings['NYQUIST'] - (*info.nyquist_list)),ind)
  widget_control,info.nyquist_id,set_combobox_select=ind

  result=where(settings.keys() eq 'MAX_FREQ',count)
  ;  result=where(tag_names(settings) eq 'MAX_FREQ',count)
  if count eq 0 then info.max_freq=max(nyquist) $
  else	info.max_freq=settings['MAX_FREQ']

  speed = info.speed_field->get_value()
  case info.freq_units of
    'ghz':info.max_freq_field->set_value,wn2ghz(info.max_freq)
    'wn':info.max_freq_field->set_value,info.max_freq
    'hz':info.max_freq_field->set_value,info.max_freq*speed
    else:message,'Unhandled frequency units!',/cont
  endcase

  info.scans_field->set_value,settings['SCANS']

  info.zpd=settings['ZPD']
  info.zpd_lw=settings['ZPD_LW']
  info.zpd_sw=settings['ZPD_SW']
  info.det_samples=settings['DET_SAMPLES']
  info.max_travel=settings['MAX_TRAVEL']
  info.min_travel=settings['MIN_TRAVEL']
  info.pso_zero_position=settings['PSO_ZERO_POSITION']
  info.encoder=settings['ENCODER']
  info.freq_resp=settings['FREQ_RESP']

  info.det_type=settings['DET_TYPE']
  info.optics=settings['OPTICS_TYPE']

  info.acceleration=settings['ACCELERATION']

  info.home_speed=settings['HOME_SPEED']

  info.start_delay=settings['START_DELAY']

  ;set up the SPcautoscale menu item
  info.autoscale_spc = settings['AUTOSCALE_SPC']
  id=widget_info(info.tlb,find_by_uname='autoscale spc')
  if info.autoscale_spc eq 0 then begin
    value='Autoscale SPC Y Axis'
    uvalue='AUTO_SPC_Y'
  endif else begin
    value='Lock SPC Y Axis'
    uvalue='LOCK_SPC_Y'
  endelse
  widget_control,id,set_value=value,set_uvalue=uvalue

  ;set up the IFG autoscale menu item
  ;  result=where(tag_names(settings) eq 'AUTOSCALE_IFG_X',count)
  result=where(settings.keys() eq 'AUTOSCALE_IFG_X',count)
  if count eq 0 then info.autoscale_ifg_x = 1 $
  else info.autoscale_ifg_x = settings['AUTOSCALE_IFG_X']
  id=widget_info(info.tlb,find_by_uname='autoscale ifg x')
  if info.autoscale_ifg_x eq 0 then begin
    value='Autoscale IFG X Axis'
    uvalue='AUTO_IFG_X'
  endif else begin
    value='Lock IFG X Axis'
    uvalue='LOCK_IFG_X'
  endelse
  widget_control,id,set_value=value,set_uvalue=uvalue

  ;  result=where(tag_names(settings) eq 'AUTOSCALE_IFG_Y',count)
  result=where(settings.keys() eq 'AUTOSCALE_IFG_Y',count)
  if count eq 0 then info.autoscale_ifg_y = 1 $
  else info.autoscale_ifg_y = settings['AUTOSCALE_IFG_Y']
  id=widget_info(info.tlb,find_by_uname='autoscale ifg y')
  if info.autoscale_ifg_y eq 0 then begin
    value='Autoscale IFG Y Axis'
    uvalue='AUTO_IFG_Y'
  endif else begin
    value='Lock IFG Y Axis'
    uvalue='LOCK_IFG_Y'
  endelse
  widget_control,id,set_value=value,set_uvalue=uvalue

  id=widget_info(info.tlb,find_by_uname='spc yscale')
  if settings['YLOG'] eq 1 then begin
    info.spc_plot->getAxisProperty,yrange=yrange
    ;make sure existing plot range isn't negative
    yrange[0] = yrange[0] > 1e-9
    yrange[1] = yrange[1] > 1e-8
    info.spc_plot->setAxisProperty,yrange=yrange
    info.spc_plot->setAxisProperty,/ylog
    info.spc_plot->show
    VALUE='Linear Spectral Intensity'
    UVALUE='LIN_SPC'
  endif else begin
    info.spc_plot->setAxisProperty,ylog=0
    info.spc_plot->show
    VALUE='Log Spectral Intensity'
    UVALUE='LOG_SPC'
  endelse
  widget_control,id,set_value=value,set_uvalue=uvalue


  ysize=settings['YSIZE'] > info.widget_min_ysize 	;limit ysize so that the buttons don't get clipped.
  widget_control,info.tlb, xsize=settings['XSIZE'], ysize=settings['YSIZE']
  info.ifg_plot->SetProperty, xsize=settings['XSIZE']-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
  info.spc_plot->SetProperty, xsize=settings['XSIZE']-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2

  info.ifg_plot->setAxisProperty,xrange=SOLOIST_FTS_POS_TO_OPD(info,[info.min_travel,info.max_travel])

  speed = info.speed_field->get_value()

  info.clock_source=settings['CLOCK_SOURCE']
  info.clock_freq=settings['CLOCK_FREQ']

  info.hk_refresh=settings['HK_REFRESH']

  case info.freq_units of
    'ghz':info.spc_plot->SetAxisProperty,xrange=[0,wn2ghz(settings['NYQUIST'])]
    'wn':info.spc_plot->SetAxisProperty,xrange=[0,settings['NYQUIST']]
    'hz':info.spc_plot->SetAxisProperty,xrange=[0,settings['NYQUIST']*speed]
    else:message,'Unhandled frequency units!',/cont
  endcase

  RRCAT_SOLOIST_FTS_update_filename,info
  return,1


end
