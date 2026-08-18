
;+
; NAME:
;	RRCAT_SOLOIST_FTS_PROCESS_SAI_TIMER
;
; PURPOSE:
;	This procedure is the event handler for the timer widget during a step
;	and integrate scan.	Each timer interval, check to see if the stage is still
;	in motion. If not, collect some samples and then append these to the
;	current interferogram. If the most recent move represents the end of the
;	given scan, compute the FFT and write the data to a file. If there are scans
;	remaining, restart the scan.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_PROCESS_SAI_TIMER, Info
;
; INPUTS:
;	Info:	The main info block from RRCAT_SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
;	Apr 10 2008 (BGG) - added triggered scan mode
; Mar 18 2012 (BGG) - added IFG autoscaling
; Nov 18 2016 (BGG) - changed to store data in infoblock instead of plot buffers.
; Aug 11 2017 (BGG) - now averages complex spectrum, no incoherent noise like mains should average out.
; Dec 14 2017 (TRF) - Modified for RRCAT. Added housekeeping
; Sep 12 2019 (TRF) - Removed double hk update
;
;
; TODO: Need to define det_samples somewhere (probably in info block).
;-
PRO RRCAT_SOLOIST_FTS_PROCESS_SAI_TIMER,info
  points=0L
  status=0L
  err=''
  speed = info.speed_field->get_value()
  IF info.abort THEN RETURN	;return immediately if abort was hit. This prevents the last timer event from
  ;being processed after an abort.

  IF NOT info.simADC THEN BEGIN
    status=SOLOIST_FTS_ADC_STATUS(/reset,model=info.adc_model,obj=info.adc_obj)
    IF ((status AND 508) GT 0) THEN BEGIN	;something bad happened. ran out of buffers, etc
      SOLOIST_FTS_MESSAGE,info, 'ADC error! Scan aborted.'
      result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
      info.scanning=0
      result=info.soloist->ABORT(err=err)
      result=DIALOG_MESSAGE(['ADC error: '+STRTRIM(status,2),$
        'Scan has been aborted.'],/info, title='Scan Error', dialog_parent=info.tlb)
      IF NOT info.simStage THEN BEGIN
        result = SOLOIST_FTS_HANDLE_SOLOIST_ERROR(info, err)
      ENDIF
      RETURN
    ENDIF
  ENDIF

  nyquist=SOLOIST_FTS_GET_NYQUIST(info)
  sampling=SOLOIST_FTS_GET_SAMPLING(info)

  ;calculate scan start position if we are simulating the stage or ADC
  IF info.simStage || info.simADC THEN BEGIN
    resolution = info.resolution_field->GET_VALUE()

    speed = info.speed_field->GET_VALUE()
    CASE info.freq_units OF
      'ghz':resolution=GHZ2WN(resolution)
      'wn':
      'hz':resolution=resolution/speed
      ELSE:MESSAGE,'Unhandled frequency units!',/cont
    ENDCASE

    IF info.FTS_Type EQ 'MZ' THEN mult=4. ELSE mult=2.
    ds_travel=info.ds_field->GET_VALUE() / mult *10. 	;mm MPD
    IF info.symmetrical THEN BEGIN
      ;min___home(0)___travel___ZPD___travel___max
      startpos=(info.ZPD-(1.21/(2.*mult*resolution/10.))) > (info.min_travel)	;the negative travel is set by the resolution
    ENDIF ELSE BEGIN
      ;min___home(0)___dstravel___ZPD___travel___max
      startpos=(info.ZPD-ds_travel) > (info.min_travel)		;the negative travel is set by the double sided travel.
    ENDELSE
  ENDIF

  ;get stage position
  IF NOT info.simStage THEN BEGIN
    pos=info.Soloist->GET_POS(err=err)
    opd=SOLOIST_FTS_POS_TO_OPD(info,pos)	;current OPD position in cm
  ENDIF ELSE BEGIN
    ;simulate the stage motion
    speed = info.speed_field->GET_VALUE() /mult * 10	;convert travel speed to mm/sec from cm/s OPD.
    IF info.symmetrical THEN BEGIN	;go twice the single sided distance
      distance = (1.21/(2.*mult*resolution/10.) *2.) 	;travel distance in mm (total double sided travel)
    ENDIF ELSE BEGIN	;go the double sided distance plus the single sided distance
      distance = (1.21/(2.*mult*resolution/10.) + ds_travel) 	;travel distance in mm (total double sided travel)
    ENDELSE
    pos=startpos + (SYSTIME(1)-info.simtime)*speed
    opd=SOLOIST_FTS_POS_TO_OPD(info,pos)	;current OPD position in cm
  ENDELSE

  IF info.samples_acquired GE 1 THEN SOLOIST_FTS_SHOW_POS,info,(*info.opd)[info.samples_acquired-1]

  ;check for new data while stage is moving

  IF NOT info.simStage THEN BEGIN
    inMotion = info.Soloist->IN_MOTION(err=err)
  ENDIF ELSE BEGIN
    ;simulate end of travel
    ;print, opd
    if opd LT (*info.opd)[info.samples_acquired-1] THEN inMotion = 1 ELSE inMotion = 0
  ENDELSE

  ; Stage is still moving to the next position. No new data to plot.
  IF inMotion THEN BEGIN
    WIDGET_CONTROL,info.sai_timer_base,timer=info.sai_refresh
    WIDGET_CONTROL, info.tlb, Set_UValue=info
    RETURN
  ENDIF

  ;
  ; If we get there. The stage has reached its next point.
  ; Sample the ADC, average these samples, and append to the data array.
  ;
  ; Start chopper/LIA and then start the ADC and collect samples to be averaged for this
  ; OPD location.
  if not info.simADC then begin
    det_samples = info.det_samples
    if not info.simChopper then begin
      ;result=RRCAT_SOLOIST_FTS_START_CHOPPER(info)
    endif
;    if not info.simLia then begin
;      RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
;      ;result=RRCAT_SOLOIST_FTS_START_LIA(info)
;    endif
    ;result=soloist_fts_adc_dump(model=info.adc_model,obj=info.adc_obj)
    ;help,result
    ;
    ; Insert a wait here to let the LIA average the sample
    ;
    sai_wait_time = info.sai_wait_field->get_value()
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
      RRCAT_SOLOIST_FTS_sensitize,info, /STEPPER, /SAI
      return
    endif
    ;
    ; Loop until we've collected the desired number of samples
    ; TODO: Do we need a wait in here?
    ;
    det_points = 0l
    WHILE det_points LT det_samples DO BEGIN
      det_points=SOLOIST_FTS_ADC_READY(model=info.adc_model,obj=info.adc_obj)
      ;IF info.debug THEN MESSAGE,STRTRIM(det_points,2)+' points ready',/info
      ;TODO- DT7816 returns only the current number of available points, not the running total
      IF info.adc_model EQ 'DT7816' THEN BEGIN
        IF det_points EQ -1 THEN BEGIN
          IF info.debug THEN MESSAGE,'ADC collection finished',/info
          det_points=det_samples
        ENDIF ELSE BEGIN
          det_points+=info.last_points
          info.last_points = det_points
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
    current_ifg = *info.ifg
    current_ifg = [current_ifg, MEAN(data)]
    info.ifg=PTR_NEW(current_ifg)
  endif

  info.samples_acquired = info.samples_acquired + 1
  points = info.samples_acquired

  ;
  ; Update the plot windows with the latest data.
  ;

  ; Need at least 2 points in order to compute the running spectrum
  ;
  ;print, points
  IF points LT 3 THEN BEGIN
    if info.simStage eq 0 then begin
      ; Compute the next end position here and go there.
      ;
      ramp_down_distance=speed^2/(2*info.acceleration)
      move_distance=sampling
      startpos = pos
      ;
      ; TODO: Should we account for the ramp_down distance here
      ; 27 April 2018: We are going to remove it for now.
      ;
      endpos=startpos+move_distance;+ramp_down_distance
      if (endpos) gt info.max_travel then SOLOIST_FTS_message,info,'Warning: interferogram extends beyond max stage travel!'
      result=info.Soloist->Move_abs( endpos < info.max_travel, speed, err=err)
      if info.debug then print,'Current Pos ' + strtrim(pos,2) + ' Moving to: '+strtrim(endpos < info.max_travel,2)+' mm'
      if(SOLOIST_FTS_handle_soloist_error(info, err)) then return
    endif
    WIDGET_CONTROL,info.sai_timer_base,timer=info.sai_refresh
    WIDGET_CONTROL, info.tlb, Set_UValue=info
    RETURN
  ENDIF

  ;
  ; We have more than 3 points. Update the running ifgm/spectrum (green plots).
  ;

  ;    if (points gt info.last_points) then begin
  ;IF info.debug THEN SOLOIST_FTS_MESSAGE,info,'samples acquired for this ifgm: '+STRTRIM(points,2)
  IF (info.simADC EQ 1) THEN BEGIN
    info.ifg=PTR_NEW((*info.simData)[0:points-1])
  ENDIF

  last=info.last_points ; TODO: Need to know the purpose of last here.

  ;calculate FFT
  ;need odd number of points.
  n=info.samples_acquired + (info.samples_acquired MOD 2) -1
  ;      print,n,n-info.buffer
  ;find an efficient length for the FFT update
  n=BEST_FFT_CLIP(n,n-info.buffer)
  ;help,n
  ;n = best_fft(n,delta=info.buffer,/down)  ;This routine takes 2 seconds to evaluate!!
  IF (n MOD 2) EQ 0 THEN n+=1
  ;      print,n
  ;      tic
  result=FFT_TO_SPECTRUM((*info.ifg)[0:n-1]-MEAN((*info.ifg)[0:n-1]), (*info.opd)[0:n-1], SPC, wn)
  ;      toc
  info.wn=PTR_NEW(wn)
  *info.spc=spc

  ;calculate the frequency grid in the given units for the plot.
  CASE info.freq_units OF
    'ghz':f=WN2GHZ(wn)
    'wn':f=wn
    'hz':BEGIN
      speed = info.speed_field->GET_VALUE()
      f=wn*speed
    END
    ELSE:MESSAGE,'unrecognized frequency units!',/cont
  ENDCASE

  ;depending on the FFT clip calculation above, the first buffer will not plot.
  ;Check if there is any data in the plot yet
  count=N_ELEMENTS(info.ifg_plot->GETDATA('current')) ;returns 1 if there are no points

  IF count EQ 1 THEN BEGIN	;this is the first set of points
    info.ifg_plot->ADD,(*info.opd)[0:points-1],(*info.ifg)[0:points-1],name='current',color=info.plot_color
    info.spc_plot->ADD,f,ABS(spc),name='current',color=info.plot_color
  ENDIF ELSE BEGIN
    ;this is not the first set of points
    info.ifg_plot->ADDTO,'current',(*info.opd)[last:points-1],(*info.ifg)[last:points-1]
    info.spc_plot->SETDATA,'current',f,ABS(spc)
    IF info.autoscale_spc THEN info.spc_plot->AUTOSCALE,/y
    IF info.autoscale_ifg_y THEN info.ifg_plot->AUTOSCALE,/y
  ENDELSE

  IF info.hide_current THEN BEGIN
    info.ifg_plot->HIDE,name='current'
    info.spc_plot->HIDE,name='current'
  ENDIF

  info.ifg_plot->SHOW
  IF info.autoscale_spc THEN info.spc_plot->AUTOSCALE,/y
  IF info.autoscale_ifg_y THEN info.ifg_plot->AUTOSCALE,/y
  info.spc_plot->SHOW
  info.last_points = points   ;this is the number of samples acquired, not the number of points plotted!

  n_opd=N_ELEMENTS(*info.opd)

  ;
  ; Are we at the end of the scan?
  ;
  IF info.samples_acquired LT n_opd THEN BEGIN
    if info.simStage eq 0 then begin
      ; Compute the next end position here and go there.
      ;
      ramp_down_distance=speed^2/(2*info.acceleration)
      move_distance=sampling
      start_pos = pos
      ;
      ; TODO: Should we account for the ramp_down distance here?
      ; 27 April 2018: We are going to remove it for now.
      ;
      endpos=start_pos+move_distance;+ramp_down_distance
      if (endpos) gt info.max_travel then SOLOIST_FTS_message,info,'Warning: interferogram extends beyond max stage travel!'
      result=info.Soloist->Move_abs( endpos < info.max_travel, speed, err=err)
      if info.debug then print,'Move distance ' + strtrim(move_distance,2)
      if info.debug then print,'Current Pos ' + strtrim(start_pos,2) + ' Moving to: '+strtrim(endpos < info.max_travel,2)+' mm'
      if(SOLOIST_FTS_handle_soloist_error(info, err)) then return
    endif
    WIDGET_CONTROL,info.sai_timer_base,timer=info.sai_refresh
    WIDGET_CONTROL, info.tlb, Set_UValue=info
    RETURN
  ENDIF

  SOLOIST_FTS_STATUS,info,'Scan completed.'

  ;
  ; plot the average
  ;
  IF info.plot_avg THEN BEGIN ;plot the averages as well as current data. This happens when there are multiple scans.
    this_scan = info.scans_field->GET_VALUE() - info.scans_remaining
    IF this_scan EQ 0 THEN BEGIN  ;first scan in sequence
      info.ifg_plot->DELETE,name='avg'
      info.spc_plot->DELETE,name='avg'
      info.ifg_plot->ADD,*info.opd,*info.ifg,name='avg',color=info.avg_color,/rear
      *info.avg_ifg=*info.ifg   ;average ifg
      *info.avg_spc=spc  ;average complex spectra
      info.spc_plot->ADD,f,ABS(spc),name='avg',color=info.avg_color,/rear
    ENDIF ELSE BEGIN  ;calculate the running average
      *info.avg_ifg = (*info.avg_ifg * this_scan + *info.ifg) / (this_scan +1)
      *info.avg_spc = (*info.avg_spc * this_scan + spc) / (this_scan +1)
      info.ifg_plot->SETDATA,'avg',*info.opd,*info.avg_ifg
      info.spc_plot->SETDATA,'avg',f,ABS(*info.avg_spc)
    ENDELSE
    IF info.hide_avg THEN BEGIN
      info.ifg_plot->HIDE,name='avg'
      info.spc_plot->HIDE,name='avg'
    ENDIF
  ENDIF

  ;write interferogram file
  IF info.debug THEN clock=tic('write files')
  hk = rrcat_soloist_fts_housekeeping(info, simHK=info.simHK, simADC=info.simADC)
  info.housekeeping = hk
  RRCAT_SOLOIST_FTS_WRITE_FILE,info

  ;write spectrum
  RRCAT_SOLOIST_FTS_WRITE_SPC,info
  IF info.debug THEN TOC,clock
  info.last_points = 0  ;reset the last point counter to zero
  info.scans_remaining --

  ;increment file number
  number=info.number_field->GET_VALUE()+1
  IF number GT 9999 THEN number=0   ;roll over file number
  info.number_field->SET_VALUE,number
  RRCAT_SOLOIST_FTS_UPDATE_FILENAME,info
  WIDGET_CONTROL,info.tlb,set_uvalue=info



  ;if more scans in sequence, start a new scan
  IF info.scans_remaining GT 0 THEN BEGIN
    RRCAT_SOLOIST_FTS_START_SAI_SCAN,info    ;PSO will remain enabled from last time.
    ;if this is triggered mode, then the DOUT 0 line will remain high.
  ENDIF ELSE BEGIN
    IF NOT info.simStage THEN result=info.soloist->DISABLE_PSO(err=err) ;disable PSO now that all scans are done.
    result=SOLOIST_FTS_HANDLE_SOLOIST_ERROR(info, err)
    SOLOIST_FTS_MESSAGE,info,'Scans Finished.'
    SOLOIST_FTS_MESSAGE,info,'Ready.'
    SOLOIST_FTS_SENSITIZE,info
    RRCAT_SOLOIST_FTS_sensitize,info, /SAI
    if info.debug EQ 1 THEN RRCAT_SOLOIST_FTS_sensitize,info, /STEPPER, /SAI
    SOLOIST_FTS_SAVE_SETTINGS,info	;save the settings again to store the new file number..
    WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    IF info.scans_field->GET_VALUE() GT 1 THEN BEGIN
      ;write average interferogram and spectrum
      RRCAT_SOLOIST_FTS_WRITE_SPC,info,/avg
      RRCAT_SOLOIST_FTS_WRITE_FILE,info,/avg
    ENDIF

    IF info.triggered THEN BEGIN
      ;This is the triggered mode, so now wait for another trigger pulse to start another scan sequence
      ;The triggered scans only stop if the abort button is hit.
      WIDGET_CONTROL,info.start_id,send_event={id:info.start_id, Top:info.tlb, handler:info.tlb, select:1}
    ENDIF
  ENDELSE
  RETURN
END