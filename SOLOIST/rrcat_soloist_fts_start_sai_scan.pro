;+
; NAME:
;	RRCAT_SOLOIST_FTS_start_sai_scan
;
; PURPOSE:
;	This procedure starts a single scan in step and integrate mode. The
;	stage is moved to home and then to the first step location. A
;	timer widget is set to periodically check to see if the next position
;	has been reached.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_start_sai_scan, Info
;
; INPUTS:
;	Info:	The main infoblock from SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Jan 17 2018.
; 	Based on SOLOIST_FTS_Start_Scan
;-

pro RRCAT_SOLOIST_FTS_start_sai_scan,info,set_PSO=set_PSO

  det_samples = info.det_samples
  Rate = 512
  sai_wait_time = 0.5
  if not info.simADC then begin
    ;det_samples = info.sai_samp_field->get_value()
    ;Rate = info.sai_freq_field->get_value()
    sai_wait_time = info.sai_wait_field->get_value()
  endif
  ;
  ;
  ;
  if keyword_set(set_PSO) then set_PSO=1 else set_PSO=0
  ;det_samples = info.det_samples
  ;desensitize input fields
  SOLOIST_FTS_DESENSITIZE,info
  if info.debug EQ 1 THEN RRCAT_SOLOIST_FTS_DESENSITIZE,info, /STEPPER

  ;should probably do this in soloist_fts_process_timer once first set of data arrives.
  ;delete previous plot
  info.ifg_plot->delete,name=['current']
  info.spc_plot->delete,name=['current']

  ;the default is for the pointers to point to !null when there is no data.
  *info.ifg=!null
  *info.spc=!null
  *info.wn=!null

  ;get the resolution, and find closest match to selected nyquist value
  resolution = info.resolution_field->get_value()

  speed = info.speed_field->get_value()
  case info.freq_units of
    'ghz':resolution=ghz2wn(resolution)
    'wn':
    'hz':resolution=resolution/speed
    else:message,'Unhandled frequency units!',/cont
  endcase

  nyquist=soloist_fts_get_nyquist(info)
  sampling=soloist_fts_get_sampling(info) ;PSO interval in mm stage travel

  if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
  ds_travel=info.ds_field->get_value()/mult*10. 	;mm MPD

  speed = info.speed_field->get_value() /mult * 10	;convert travel speed to mm/sec from cm/s OPD.
  if info.symmetrical then begin	;go twice the single sided distance
    distance = (1.21/(2.*mult*resolution/10.) *2.) 	;travel distance in mm (total double sided travel)
  endif else begin	;go the double sided distance plus the single sided distance
    distance = (1.21/(2.*mult*resolution/10.) + ds_travel) 	;travel distance in mm (total double sided travel)
  endelse

  ;calculate starting position of the interferogram (PSO window starts here)

  if info.symmetrical then begin
    ;min___home(0)___travel___ZPD___travel___max
    startpos=(info.ZPD-(1.21/(2.*mult*resolution/10.))) > (info.min_travel)	;the negative travel is set by the resolution
  endif else begin
    ;min___home(0)___dstravel___ZPD___travel___max
    startpos=(info.ZPD-ds_travel) > (info.min_travel)		;the negative travel is set by the double sided travel.
  endelse

  ;startpos does not include distance for acceleration prior to window.
  ;get the default acceleration rate
  accel=info.acceleration  ;mm/sec^2
  if info.simStage eq 0 then begin
    ;update the default acceleration in the soloist
    if info.simStage eq 0 then begin
      err=''
      result=info.Soloist->SET_PARAMETER( 'DefaultRampRate',info.acceleration, err=err)
      if(SOLOIST_FTS_handle_soloist_error(info, err)) then begin
        SOLOIST_FTS_message,info,'Error setting acceleration. Check Soloist is configured to use parameter names instead of numbers.'
        return
      endif
    endif
  endif

  ramp_up_distance=speed^2/(2*accel) > (10*sampling) ;  go at least ten samples beyond the start of the interferogram.
  ramp_down_distance=speed^2/(2*accel)  ;also go speed^2/(2*accel) beyond end of interferogram to ensure stage isn't decelerating!

  if info.debug then begin
    SOLOIST_FTS_message,info,'Sampling: '+strtrim(sampling,2)+' (mm mechanical)'
    SOLOIST_FTS_message,info,'Speed: '+strtrim(speed,2)+' (mm/sec mechanical)'
    SOLOIST_FTS_message,info,'Acceleration: '+strtrim(accel,2)+' (mm/sec^2 mechanical)'
    SOLOIST_FTS_message,info,'PSO rate: '+strtrim(speed/sampling,2)+' (Hz)'
    SOLOIST_FTS_message,info,'Start pos: '+strtrim(startpos,2)+' (mm mechanical)'
    SOLOIST_FTS_message,info,'ZPD: '+strtrim(info.zpd,2)+' (mm mechanical)'
    SOLOIST_FTS_message,info,'Ramp Up Distance: '+strtrim(ramp_up_distance,2)+' (mm mechanical)'
    SOLOIST_FTS_message,info,'Ramp Down Distance: '+strtrim(ramp_up_distance,2)+' (mm mechanical)'
    SOLOIST_FTS_message,info,'IFG Distace: '+strtrim(distance,2)+' (mm mechanical)'
    SOLOIST_FTS_message,info,'Total Distace: '+strtrim(distance+ramp_up_distance+ramp_down_distance,2)+' (mm mechanical)'
  endif


  ;move stage to start minus ramp_up_distance (home takes too long)
  err=0
  if info.simStage eq 0 then begin
    widget_control,/hourglass
    result=info.soloist->SET_WAIT_MODE('NOWAIT',err=err) ;soloist will respond to next command immediately. This should already be set in the initialization.
    result = SOLOIST_FTS_handle_soloist_error(info, err)
    if (startpos-ramp_up_distance) lt info.min_travel then SOLOIST_FTS_message,info,'Warning: interferogram extends beyond min stage travel!'
    result=info.soloist->move_abs((startpos-ramp_up_distance)>(info.min_travel), info.home_speed, err=err)		;go the double sided distance before ZPD, but no further than the minimum travel.
    if info.debug then SOLOIST_FTS_message,info,'Moving to: '+strtrim((startpos-ramp_up_distance)>(info.min_travel),2)+' mm'
    result = SOLOIST_FTS_handle_soloist_error(info, err)
    while (info.Soloist->In_Motion(err=err)) and (err eq '') do begin
      ;get stage position and update plot
      opd=SOLOIST_FTS_pos_to_opd(info,info.Soloist->Get_Pos( err=err ))	;current OPD position in cm
      SOLOIST_FTS_show_pos,info,opd
      wait, 0.1
    endwhile
    widget_control,hourglass=0

    ;    while abs(info.Soloist->Get_Pos( err=err ) - startpos) gt 0.001 and (err eq '') do begin
    ;      wait, 0.05
    ;      endwhile
  endif

  if info.autoscale_ifg_x then info.ifg_plot->SetAxisProperty,xrange=SOLOIST_FTS_pos_to_opd(info,[startpos,startpos+distance])

  info.plot_title = info.measurement_type+' '+info.optics+' '+info.det_type+' '+info.fts_selected
  info.ifg_plot->SetProperty,Title=info.plot_title	;add title to plot
  info.ifg_plot->show

  samples = floor(distance/sampling)   ;It should be so simple, but the ADC seems to only like filling buffers in multples of 32 points!!

  ;May 2015 - We've already made sure the buffer length is an integer multiple of 32, now make sure the scan length
  ; is an integer multiple of the buffer length. This means that the buffer length should be set to be reasonably small, so
  ; that not too much time is wasted at the end of the scan.

  ;
  ; TODO: It might be good to keep this definition of samples (i.e samples in OPD)
  ; But a new definition will be needed for S&I as we will have to record a set of
  ; samples at each position.
  ;
  IF info.buffer NE 0l THEN samples += (info.buffer - (samples mod info.buffer))

  ;
  ; TODO: Might not need to modify this one even though we are in S&I mode.
  ; OR should we just record the actual position instead?
  ;
  *info.opd=SOLOIST_FTS_pos_to_opd(info,startpos + dindgen(samples)*(sampling))	;OPD grid in cm
  info.dio.scanning  = 1b
  bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
  if info.simADC eq 0 then begin
    IF info.debug THEN BEGIN
      SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to '+STRING(bitVal)
    ENDIF
    result=RRCAT_SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)	;the FTS status is 'scanning'.
  endif
  ;start PSO if this is the first scan
  ;use the pso windowing function to ensure samples start and end at correct positions
  if info.simStage eq 0 && set_PSO then begin
    ;    result=info.soloist->CONFIGURE_PSO_WINDOW(startpos, startpos+distance, sampling, err=err)
    result=info.soloist->CONFIGURE_PSO_WINDOW(startpos, startpos+(samples*sampling), sampling, err=err)
    if err ne '' then SOLOIST_FTS_message,info,err
    err=''
    ;check for soloist faults
    if(SOLOIST_FTS_handle_soloist_error(info, err)) then return

    ;start the PSO
    result=info.soloist->enable_pso(err=err)
    if(SOLOIST_FTS_handle_soloist_error(info, err)) then return

    if info.debug then begin
      SOLOIST_FTS_message,info,'PSO Window: '+strtrim(startpos,2)+' to '+strtrim(startpos+(samples*sampling),2)+' (mm mechanical)'
      SOLOIST_FTS_message,info,'PSO Interval: '+strtrim(sampling,2)+' (mm mechanical)'
    endif

  endif

  ;optional delay at start of scan.
  if info.start_delay gt 0 then begin
    SOLOIST_FTS_message,info,string(info.start_delay,format='("Delaying ",F0.1," seconds...")')
    wait,info.start_delay
  endif

  ;start chopper/LIA and then start the ADC and collect the first sample
  info.last_points = 0
  if not info.simADC then begin
    ;Rate = 512
    clock_source = 1
    clock_freq = Rate
    Channel_array       = [0, 1, 2, 3, 4, 5, 6]
    Range_array       = ['BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10', 'BIP10']
    model=info.adc_model
    obj=info.adc_obj
    ;
    ; Set up the ADC to use the internal clock in SAI mode.
    ;
    IF OBJ_VALID(obj) THEN BEGIN
      result=obj->CONFIGURE(a_channels=a_channels, a_RATE=clock_freq, a_RANGES = a_ranges, a_extclock=~clock_source )
    ENDIF
    IF not info.simChopper THEN BEGIN
      ;result=RRCAT_SOLOIST_FTS_START_CHOPPER(info)
    ENDIF
    IF not info.simLia THEN BEGIN
      RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
      ;result=RRCAT_SOLOIST_FTS_START_LIA(info)
    ENDIF
    ;result=soloist_fts_adc_dump(model=info.adc_model,obj=info.adc_obj)
    ;help,result
    nSamples = det_samples
    ;
    ; Insert a wait here to let the LIA average the sample
    ;
    
    wait, sai_wait_time

    nSamples = det_samples
    if info.debug then SOLOIST_FTS_message,info,'Collecting '+strtrim(nSamples,2)+' samples...'
    result=SOLOIST_FTS_ADC_COLLECT(nSamples,model=info.adc_model,obj=info.adc_obj)

    if result ne 1 then begin
      SOLOIST_FTS_message,info,'ADC acquisition failed: '+strtrim(result,2)
      status=SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj)
      if status eq !null then begin
        ;something bad happened. Probably lost connection to ADC
        status='Communication lost!'
      endif
      SOLOIST_FTS_message,info,'ADC status: '+strtrim(status,2)
      result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
      SOLOIST_FTS_sensitize,info
      IF info.simStepper EQ 0 THEN BEGIN
        RRCAT_SOLOIST_FTS_SENSITIZE,info, /STEPPER
      ENDIF
      return
    endif

    points=0l
    ;
    ; Loop until we've collected the desired number of samples
    ; TODO: Do we need a wait in here?
    ;
    WHILE points LT det_samples DO BEGIN
      points=SOLOIST_FTS_ADC_READY(model=info.adc_model,obj=info.adc_obj)
      IF info.debug THEN MESSAGE,STRTRIM(points,2)+' points ready',/info
      ;TODO- DT7816 returns only the current number of available points, not the running total
      IF info.adc_model EQ 'DT7816' THEN BEGIN
        IF POINTS EQ -1 THEN BEGIN
          IF info.debug THEN MESSAGE,'ADC collection finished',/info
          points=det_samples
        ENDIF ELSE BEGIN
          points+=info.last_points
          info.last_points = points
        ENDELSE
      ENDIF
    ENDWHILE
    ;
    ; Finished with this sample, start the data vector
    ;
    data=RRCAT_SOLOIST_FTS_ADC_DUMP(model=info.adc_model,obj=info.adc_obj)
    case info.det_type of
      'TES':data=REFORM(data[*,0])
      'HEB':data=REFORM(data[*,0])
      'MCT':data=REFORM(data[*,1])
      'Pyro-1':data=REFORM(data[*,2])
      'Pyro-2':data=REFORM(data[*,2])
    endcase
    info.ifg=PTR_NEW(MEAN(data))
  endif else begin
    ;simulate data
    *info.simData=!null

    ;set up 1/f noise with a knee at ~5 Hz
    if samples mod 2 eq 0 then noise_pts=samples-1 else noise_pts=samples	;ensure odd  # of points. We may have 1 fewer points, but that doesn't matter
    noise=randomu(systime(1),noise_pts)
    result=fft_to_spectrum(noise,(*info.opd)[0:noise_pts-1],noise_spc,noise_wn)
    f=info.speed_field->get_value()*noise_wn  ;get frequency scale in Hz
    f[0]=1
    f_noise=(1./f^.5)*noise_spc
    f_noise[0]=f_noise[1]	;get rid of large DC noise component
    result=fft_to_interferogram(f_noise,noise_wn, int_noise, noise_opd)
    int_noise=shift(int_noise,noise[0]*noise_pts)	;shift by some random amount so we don't always have a large bump near ZPD

    ;simulate 320GHz line
    period=1d/ghz2wn(320)
    ;simulate a 450cm-1 line
    ;period=1d/450.
    signal=cos((*info.opd+0.5)/period*2*!pi)	;cosine wave with 0.1cm phase shift
    signal[0:n_elements(noise_opd)-1]+=bgg_normalize(int_noise)	*2

    ;TODO- simulate mains 120 Hz noise with random phase.
    mains_period=1./(120./info.speed_field->get_value())
    mains_signal=cos(((*info.opd)/mains_period + randomu(systime(1))-0.5)*2*!pi)  ;cosine wave with some random phase shift betwen -pi and +pi

    signal+=mains_signal/2.

    signal=signal/10.+0.5

    info.simData=ptr_new(signal)	;100mV signal on a 0.5V DC, S/N=2, 1mm OPD shift
  endelse

  ;start motion
  ;
  ; TODO: Should we just compute the entire OPD grid right now and then just step to each point
  ; This might be easier. We would know each position and the total number of positions,
  ; Then we would just need to keep track of how many points have been
  ; gathered
  ;
  if info.simStage eq 0 then begin
    ; Compute the next end position here and go there.
    ;
    move_distance=sampling

    ;
    ; TODO: Should we account for the ramp_down distance here
    ;
    endpos=startpos+move_distance;+ramp_down_distance
    if (endpos) gt info.max_travel then SOLOIST_FTS_message,info,'Warning: interferogram extends beyond max stage travel!'
    result=info.Soloist->Move_abs( endpos < info.max_travel, speed, err=err)
    if info.debug then print,'Moving to: '+strtrim(endpos < info.max_travel,2)+' mm'
    if(SOLOIST_FTS_handle_soloist_error(info, err)) then return
  endif

  SOLOIST_FTS_status,info, strtrim(string(info.scans_remaining,format='(I4," scans remaining.")'),2)
  SOLOIST_FTS_status,info, 'Scan started..'
  info.samples_acquired = 1
  ;for multiple scans, plot the average IFG and SPC
  if info.scans_remaining gt 1 then info.plot_avg = 1 else info.plot_avg = 0

  if info.simStage or info.simADC then info.simtime=systime(1)

  ;set the sia timer to start processing data
  widget_control,info.sai_timer_base,timer=info.sai_refresh

end
