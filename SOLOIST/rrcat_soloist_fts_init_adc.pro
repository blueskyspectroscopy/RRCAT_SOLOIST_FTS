;+
; NAME:
;	SOLOIST_FTS_INIT_ADC
;
; PURPOSE:
;	This function connects to the ADC controller. Called by SOLOIST_FTS. Returns 1 on success.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=SOLOIST_FTS_INIT_ADC(info)
;
; INPUTS:
;	info:	The main info block.
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Jul 1 2009
; 	Nov 25 2009 (BGG) - added the option to use the internal clock instead of the TTL trigger
;   Aug 16 2016 (BGG) - extended for use with DT7816 object
;   Apr 05 2018 (TRF) - Fixed typo to clock_freq argument to SOLOIST_FTS_ADC_init()
;   Apr 05 2018 (TRF) - extended for RRCAT to include a clock_source argument to SOLOIST_FTS_ADC_init()
;-


function RRCAT_SOLOIST_FTS_INIT_ADC, info

  adc_init:

  if info.debug then SOLOIST_FTS_message,info,'Initializing ADC'
  widget_control,/hourglass

  ;the buffer length is in seconds. compute the number of samples at the given sampling interval and speed
  sampling=soloist_fts_get_sampling(info) ;pso interval in mm.
  if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
  ds_travel=info.ds_field->get_value()/mult*10.   ;mm MPD
  speed = info.speed_field->get_value() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.

  ;  bufflen = 2L > long(info.buffer*speed/sampling)    ;n seconds worth of sampling intervals
  ;;have at least 3 buffers, or enough for at least 10 seconds worth of data
  ;  n_buff = 3L > long(10./info.buffer)

  ;  May 2015 - changed to define buffer length in samples instead of time.

  ;  bufflen = 32L > long(info.buffer) ;make sure we have at least 32 points.
  ;  bufflen -= bufflen mod 32 ;make sure it is a multiple of 32
  bufflen = info.buffer ;the length should already be a multiple of 32

  ; have at least 3 buffers or at least 30 seconds worth of buffers. This shouldn't be an
  ; unreasonable amount of memory, at 100khz this is ~12 MB.
  IF bufflen NE 0 then begin
    n_buff = long(3 > speed/sampling*30./bufflen)
  ENDIF else begin
    n_buff = 3l
  endelse

  if info.simADC then result=1 else begin
    result=SOLOIST_FTS_ADC_close(model=info.adc_model,obj=info.adc_obj)	;make sure it is closed in case another instance is still running
    if info.clock_source eq 0 then freq=0d else freq=info.clock_freq
    obj=info.adc_obj
    ;
    ; TRF EDIT
    ; Check to see if info.clock_source EQ 1
    ; IF so, set up clock_freq=freq to be equal to
    ; the expected number of samples given the speed and
    ; total distance
    ;
    IF info.clock_source EQ 1 THEN BEGIN
      nyquist=soloist_fts_get_nyquist(info)
      sampling=soloist_fts_get_sampling(info) ;PSO interval in mm stage travel

      if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
      ds_travel=info.ds_field->get_value()/mult*10.   ;mm MPD
      resolution = info.resolution_field->get_value()

      speed = info.speed_field->get_value()
      case info.freq_units of
        'ghz':resolution=ghz2wn(resolution)
        'wn':
        'hz':resolution=resolution/speed
        else:message,'Unhandled frequency units!',/cont
      endcase
      speed = info.speed_field->get_value() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.
      if info.symmetrical then begin  ;go twice the single sided distance
        distance = (1.21/(2.*mult*resolution/10.) *2.)  ;travel distance in mm (total double sided travel)
      endif else begin  ;go the double sided distance plus the single sided distance
        distance = (1.21/(2.*mult*resolution/10.) + ds_travel)  ;travel distance in mm (total double sided travel)
      endelse
      sampling=soloist_fts_get_sampling(info) ;PSO interval in mm stage travel
      samples = floor(distance/sampling)
      time = distance/speed
      freq = samples/time
      info.clock_freq = freq
      if info.debug then begin
        SOLOIST_FTS_message,info,'Sampling: ' + strtrim(sampling,2) + ' (mm mechanical)'
        SOLOIST_FTS_message,info,'Speed: ' + strtrim(speed,2) + ' (mm/sec mechanical)'
        SOLOIST_FTS_message,info,'Time ' + strtrim(time, 2) + ' (sec)'
        SOLOIST_FTS_message,info,'Freq ' + strtrim(info.clock_freq , 2) + ' (Hz)'
      endif
    ENDIF
    ;
    result=RRCAT_SOLOIST_FTS_ADC_init(bufflen=bufflen,n_buff=n_buff,gain=info.gain,debug=info.debug,$
      mc1808x_serial=info.mc1808x_serial, model=info.adc_model,clock_freq=freq,obj=obj,IP=info.ADC_IP, $
      clock_source=info.clock_source, a_channels=info.a_channels)
  endelse

  widget_control,hourglass=0

  if result eq 1 then begin
    if info.debug THEN SOLOIST_FTS_status,info,'ADC Initialized.'
    ADC_connected=1
    if info.simADC eq 0 then info.adc_obj=obj
  endif else begin
    SOLOIST_FTS_message,info,'ADC init failed: '+string(result)
    if info.simADC then	result=1 else $
      result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
    result=dialog_message(['ADC failed to initialize.','Verify connection to the ADC module and hit OK.'],/info,title='ADC error')

    result=dialog_message('Retry initialization?',/question,title='ADC error')
    if result eq 'Yes' then goto,adc_init
    ;		Widget_Control, id, /destroy
    ;		return
    ADC_connected=0
  endelse

  return,ADC_Connected	;only return 1 if we actually connected to the ADC
end