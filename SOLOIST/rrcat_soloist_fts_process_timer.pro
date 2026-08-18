;+
; NAME:
;	RRCAT_SOLOIST_FTS_PROCESS_TIMER
;
; PURPOSE:
;	This procedure is the event handler for the timer widget during a scan.
;	Each timer interval, the ADC is polled for new data, the stage position
;	is plotted, and the FFT is calculated. At the end of the scan the data
;	is written to a file and a new scan is started if required.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_PROCESS_TIMER, Info
;
; INPUTS:
;	Info:	The main info block from SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
;	Apr 10 2008 (BGG) - added triggered scan mode
; Mar 18 2012 (BGG) - added IFG autoscaling
; Nov 18 2016 (BGG) - changed to store data in infoblock instead of plot buffers.
; Aug 11 2017 (BGG) - now averages complex spectrum, no incoherent noise like mains should average out.
; Dec 14 2017 (TRF) - Modified for RRCAT. Added housekeeping
; Jul 03 2019 (TRF) - Only check actual housekeeping every 10th scan.
; Jul 04 2019 (TRF) - Only check actual housekeeping on last scan.
; Jul 08 2019 (TRF) - Only update housekeeping on last scan.
; Jul 12 2019 (TRF) - Now used for Step and Integrate mode.
; Jul 29 2019 (TRF) - Added more timing diagnositcs
; Jul 31 2019 (TRF) - Added more timing diagnositcs
; Aug 06 2019 (TRF) - Added profiler at the end of a scan sequence
; Aug 16 2019 (TRF) - Restart stepper comms after a set of scans
; Aug 29 2019 (TRF) - Restarting stepper comms no longer needed
; Aug 29 2019 (TRF) - Removed superfluous calls to toc()
;-


PRO RRCAT_SOLOIST_FTS_PROCESS_TIMER,info
  points=0L
  status=0L
  err=''

  IF info.abort THEN RETURN	;return immediately if abort was hit. This prevents the last timer event from
  ;being processed after an abort.

  IF NOT info.simADC THEN BEGIN
    status=SOLOIST_FTS_ADC_STATUS(/reset,model=info.adc_model,obj=info.adc_obj)
    ;IF info.debug NE 0 THEN SOLOIST_FTS_MESSAGE,info, 'ADC Status:'+STRTRIM(status, 2)
    IF ((status AND 508) GT 0) THEN BEGIN	;something bad happened. ran out of buffers, etc
      SOLOIST_FTS_MESSAGE,info, 'ADC error! Scan aborted.'
      result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
      info.scanning=0

      result=info.soloist->ABORT(err=err)
      result=DIALOG_MESSAGE(['ADC error: '+STRTRIM(status,2),$
        'Scan has been aborted.'],/info, title='Scan Error', dialog_parent=info.tlb)
      SOLOIST_FTS_SENSITIZE,info
      RRCAT_SOLOIST_FTS_SENSITIZE,info, /STEPPER
      IF NOT info.simStage THEN BEGIN
        ;        result=info.Soloist->Home( ERR=err)
        ;homing the stage is too time consuming. Return to start?
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

  SOLOIST_FTS_SHOW_POS,info,opd

  ;check for new data while stage is moving

  IF NOT info.simStage THEN BEGIN
    inMotion = info.Soloist->IN_MOTION(err=err)
  ENDIF ELSE BEGIN
    ;simulate end of travel
    ;print, pos -(startpos + distance)
    IF pos LT startpos + distance THEN inMotion = 1 ELSE inMotion = 0
  ENDELSE

  ;scan is still in progress
  IF inMotion THEN BEGIN
    IF info.simADC EQ 0 THEN BEGIN
      points=SOLOIST_FTS_ADC_READY(model=info.adc_model,obj=info.adc_obj)
      points = points/N_ELEMENTS(info.a_channels)
      IF info.debug THEN MESSAGE,STRTRIM(points,2)+' points ready',/info
      ;TODO- DT7816 returns only the current number of available points, not the running total
      IF info.adc_model EQ 'DT7816' THEN BEGIN
        IF POINTS EQ -1 THEN BEGIN
          IF info.debug THEN MESSAGE,'ADC collection finished',/info
          points=0
        ENDIF
        points+=info.last_points
      ENDIF
    ENDIF ELSE BEGIN
      ;simulate data
      points=LONG((pos-startpos)/sampling) < N_ELEMENTS(*info.simData)
    ENDELSE

    ;need at least 2 points each time, so if position hasn't changed by 2 samples
    ;then return. This can happen in the simulator mode. The ADC buffer normally takes
    ;care of this. In the simulator mode, simulate the buffer here.
    IF info.simADC THEN BEGIN
      speed = info.speed_field->GET_VALUE() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.
      ;min_points=2>long(info.buffer*speed/sampling)
      ;May 2015- buffer now defined in samples not time
      min_points=2>LONG(info.buffer)
      ;    endif else min_points=2
    ENDIF ELSE min_points=LONG(info.buffer)   ; require at least a 'buffer' worth of points. This is the buffer length in the gui- for some ADCs the buffer size is arbitrary

    IF points-info.last_points LE min_points THEN BEGIN ;***** TRF
      WIDGET_CONTROL,info.timer_base,timer=info.refresh
      RETURN
    ENDIF ELSE BEGIN
      ;    if (points gt info.last_points) then begin
      ;IF info.debug THEN SOLOIST_FTS_MESSAGE,info,'points > info.last_points + min_points: '+STRTRIM(points,2)
      IF (info.simADC EQ 0) THEN BEGIN
        ;new buffer is full. Get data, calculate FFT and update plots
        data=SOLOIST_FTS_ADC_DUMP(model=info.adc_model,obj=info.adc_obj)
        case info.det_type of
          'TES':data=REFORM(data[*,0])
          'HEB':data=REFORM(data[*,0])
          'MCT':data=REFORM(data[*,1])
          'Pyro-1':data=REFORM(data[*,2])
          'Pyro-2':data=REFORM(data[*,2])
        endcase
        ;help, data
        IF info.adc_model EQ 'DT7816' THEN BEGIN  ;DT7816 only returns data recorded since last dump, not entire acquisition.
          ;if info.last_points gt 0 then begin
          ;add the data to the full array
          ;*info.ifg=[*info.ifg,data]
          ;endif
          *info.ifg=[*info.ifg,data]

        ENDIF ELSE BEGIN  ;other ADC models return all data
          info.ifg=PTR_NEW(data)
        ENDELSE

        data=!null
        ;        endif
        ;end of todo

      ENDIF ELSE BEGIN ;simADC eq 1
        info.ifg=PTR_NEW((*info.simData)[0:points-1])
      ENDELSE

      last=info.last_points

      ;calculate FFT
      ;      wn=findgen(points/2+1)/(points/2.) * nyquist
      ;      d=(*info.ifg)[0:points-1]
      ;      spc=(abs(fft(d-mean(d))))[0:points/2]

      ;need odd number of points.
      n=points + (points MOD 2) -1
      ;      print,n,n-info.buffer
      ;find an efficient length for the FFT update
      n=BEST_FFT_CLIP(n,n-info.buffer)
      ;help,n
      ;n = best_fft(n,delta=info.buffer,/down)  ;This routine takes 2 seconds to evaluate!!
      IF (n MOD 2) EQ 0 THEN n+=1
      ;      print,n
      ;      tic
      IF n GT 3 THEN BEGIN

        result=FFT_TO_SPECTRUM((*info.ifg)[0:n-1]-MEAN((*info.ifg)[0:n-1]), (*info.opd)[0:n-1], SPC, wn)
        ;      toc
        info.wn=PTR_NEW(wn)

        ;      *info.spc=(abs(fft(d-mean(d))))[0:points/2]
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

      ENDIF ;if there are more than 3 points

      IF info.hide_current THEN BEGIN
        info.ifg_plot->HIDE,name='current'
        info.spc_plot->HIDE,name='current'
      ENDIF
      info.ifg_plot->SHOW
      info.spc_plot->SHOW
      info.last_points = points   ;this is the number of samples acquired, not the number of points plotted!
    ENDELSE  ;points > last_points+buffer

    WIDGET_CONTROL,info.timer_base,timer=info.refresh
    WIDGET_CONTROL, info.tlb, Set_UValue=info
    RETURN
  ENDIF ELSE BEGIN
    ;scan not in motion

    ;stop PSO (not required if using windowed mode.
    ;		if info.simStage eq 0 then begin
    ;			result=info.soloist->disable_pso(err=err)
    ;			if(SOLOIST_FTS_handle_soloist_error(info, err)) then return
    ;			endif

    IF info.simADC EQ 0 THEN BEGIN
      ;			result=SOLOIST_FTS_ADC_stop(model=info.adc_model,obj=info.adc_obj)
      ;TODO- DT7816 only returns data since last dump. NEed to maintain a data array in the infoblock
      IF info.adc_model EQ 'DT7816' THEN BEGIN
        ;        plotdata=info.ifg_plot->getData('current')
        ;        if n_elements(plotdata) eq 1 then plotdata=!null else plotdata=reform(plotdata[1,*])
        newdata=SOLOIST_FTS_ADC_DUMP(model=info.adc_model,obj=info.adc_obj)
        IF info.debug THEN SOLOIST_FTS_MESSAGE,info,'Scan finished. DT7816 dump returned '+STRTRIM(N_ELEMENTS(newdata),2)+' points.'
        IF newdata EQ !null THEN BEGIN
          ;          stop
          ;dump will fail if there is no data. This is probably ok.
        ENDIF ELSE BEGIN
          case info.det_type of
            'TES':newdata=REFORM(newdata[*,0])
            'HEB':newdata=REFORM(newdata[*,0])
            'MCT':newdata=REFORM(newdata[*,1])
            'Pyro-1':newdata=REFORM(newdata[*,2])
            'Pyro-2':newdata=REFORM(newdata[*,2])
          endcase
          *info.ifg=[*info.ifg,newdata]
        ENDELSE
        ;        data=[temporary(plotdata),temporary(newdata)]
      ENDIF ELSE BEGIN
        newdata=SOLOIST_FTS_ADC_DUMP(model=info.adc_model,obj=info.adc_obj)
        IF newData NE !NULL THEN BEGIN
          case info.det_type of
            'TES':newdata=REFORM(newdata[*,0])
            'HEB':newdata=REFORM(newdata[*,0])
            'MCT':newdata=REFORM(newdata[*,1])
            'Pyro-1':newdata=REFORM(newdata[*,2])
            'Pyro-2':newdata=REFORM(newdata[*,2])
          endcase
          *info.ifg=TEMPORARY(newdata)
        ENDIF
      ENDELSE
    ENDIF ELSE BEGIN
      *info.ifg=*info.simData
    ENDELSE
    ;if there weren't enough points, send a message
    points=N_ELEMENTS(*info.ifg)
    IF POINTS EQ 0 THEN BEGIN
      SOLOIST_FTS_MESSAGE,info,"Motion stopped, but didn't collect any points!"
    ENDIF
    n_opd=N_ELEMENTS(*info.opd)

    IF POINTS GT n_opd THEN BEGIN
      *info.ifg = (*info.ifg)[0:n_opd-1]
      SOLOIST_FTS_MESSAGE,info,'Motion stopped, but collected '+STRTRIM(points-n_opd,2)+' points more than the expected ' + STRTRIM(n_opd,2)+ '!'
    ENDIF
    IF POINTS LT n_opd THEN BEGIN
      IF POINTS EQ 0 THEN BEGIN
        SOLOIST_FTS_MESSAGE,info,'Motion stopped, but but no points collected of '+STRTRIM(n_opd,2)+' expected!'
        ;check for drive errors. This should probably be done somewhere else, so that whenever a fault occurs the message is displayed immediately.
        SOLOIST_FTS_FAULT_MESSAGE,info
      ENDIF ELSE BEGIN
        temp = (*info.opd) * 0 + MEAN(*info.ifg)
        temp[0]=*info.ifg
        *info.ifg=TEMPORARY(temp)
        SOLOIST_FTS_MESSAGE,info,'Motion stopped, but only '+STRTRIM(points,2)+' of '+STRTRIM(n_opd,2)+' points collected! ('+STRTRIM(FLOAT(n_opd-points)/info.buffer,2)+' buffers missing)'
        ;check for drive errors. This should probably be done somewhere else, so that whenever a fault occurs the message is displayed immediately.
        SOLOIST_FTS_FAULT_MESSAGE,info
      ENDELSE
    ENDIF
    if info.debug THEN SOLOIST_FTS_message,info,'Motion Stopped: '+timestamp()
    IF info.simADC EQ 0 THEN result=SOLOIST_FTS_ADC_STOP(model=info.adc_model,obj=info.adc_obj)

    ;TODO- should we trim the OPD length instead?
    ;Use the length of the OPD grid regardless of how many real data points were collected
    points=N_ELEMENTS(*info.ifg)

    ;		if points ne n_elements(*info.opd) then begin	;there were not enough points
    ;			if info.debug then soloist_fts_message,info,'motion stopped, but only '+strtrim(points,2)+' of '+strtrim(n_elements(*info.opd),2)+' points collected!'
    ;			soloist_fts_message,info,'Final ADC buffer was not filled!'
    ;			result=dialog_message(['Final ADC buffer was not filled!',$
    ;			  string(points,n_elements(*info.opd),format='("Collected ",I0," points but expected ",I0)'),$
    ;				'Adjust buffer size or travel distance!'],/err,dialog_parent=info.tlb,$
    ;				title='Acquisition Error')
    ;
    ;			endif else begin  ;there was enough points

    IF POINTS GT 0 THEN BEGIN

      ;calculate FFT
      ;      wn=findgen(points/2+1)/(points/2.) * nyquist
      ;      ;		spc=(abs(fft(data[0:points-1])))[0:points/2]
      ;      spc=(abs(fft(data-mean(data))))[0:points/2]

      ;need odd number of points.
      n=points + (points MOD 2) -1

      ;Sept 25 2017- final FFT is taking many seconds.
      ;Should we clip or pad here?
      IF info.buffer EQ 0l OR n/info.buffer GT 3 THEN BEGIN
        n=BEST_FFT_CLIP(n,n-info.buffer)
        IF (n MOD 2) EQ 0 THEN n+=1
        IF info.debug THEN SOLOIST_FTS_MESSAGE,info,'Clipping from '+STRTRIM(points,2)+' to '+STRTRIM(n,2)+' points.'
      ENDIF

      ;      if info.debug then clock=tic('Final FFT')
      result=FFT_TO_SPECTRUM((*info.ifg)[0:n-1]-MEAN((*info.ifg)[0:n-1]), (*info.opd)[0:n-1], SPC, wn)
      ;      if info.debug then toc,clock
      ptr_free,info.wn,info.spc
      info.wn=PTR_NEW(wn)
      info.spc=ptr_new(spc)

      ;update plots
      IF info.ifg_plot->ISCONTAINED('current') THEN BEGIN
        info.ifg_plot->SETDATA,'current',*info.opd,*info.ifg
      ENDIF ELSE BEGIN  ;for short scans, we may not have had a timer event yet to add the plot
        info.ifg_plot->ADD,*info.opd,*info.ifg,name='current',color=info.plot_color
      ENDELSE

      CASE info.freq_units OF
        'ghz':f=WN2GHZ(wn)
        'wn':f=wn
        'hz':BEGIN
          speed = info.speed_field->GET_VALUE()
          f=wn*speed
        END
        ELSE:MESSAGE,'unrecognized frequency units!',/cont
      ENDCASE

      IF info.spc_plot->ISCONTAINED('current') THEN BEGIN
        info.spc_plot->SETDATA,'current',f,ABS(spc)
      ENDIF ELSE BEGIN  ;for short scans, we may not have had a timer event yet to add the plot
        info.spc_plot->ADD,f,ABS(spc),name='current',color=info.plot_color
      ENDELSE

      IF info.plot_avg THEN BEGIN	;plot the averages as well as current data. This happens when there are multiple scans.
        this_scan = info.scans_field->GET_VALUE() - info.scans_remaining

        IF this_scan EQ 0 THEN BEGIN	;first scan in sequence
          info.ifg_plot->DELETE,name='avg'
          info.spc_plot->DELETE,name='avg'
          info.ifg_plot->ADD,*info.opd,*info.ifg,name='avg',color=info.avg_color,/rear
          *info.avg_ifg=*info.ifg   ;average ifg
          *info.avg_spc=spc  ;average complex spectra

          info.spc_plot->ADD,f,ABS(spc),name='avg',color=info.avg_color,/rear

        ENDIF ELSE BEGIN	;calculate the running average
          ;          old_ifg_data = (info.ifg_plot->getData('avg'))[1,*]
          ;          ifg_avg = (old_ifg_data * this_scan + data) / (this_scan + 1)
          ;          info.ifg_plot->setData,'avg',*info.opd,ifg_avg
          ;
          ;          old_spc_data = (info.spc_plot->getData('avg'))[1,*]
          ;          spc_avg = (old_spc_data * this_scan + spc) / (this_scan + 1)
          IF *info.avg_ifg NE !NULL THEN BEGIN
            *info.avg_ifg = (*info.avg_ifg * this_scan + *info.ifg) / (this_scan +1)
            info.ifg_plot->SETDATA,'avg',*info.opd,*info.avg_ifg
          ENDIF
          IF *info.avg_spc NE !NULL THEN BEGIN
            *info.avg_spc = (*info.avg_spc * this_scan + spc) / (this_scan +1)
            info.spc_plot->SETDATA,'avg',f,ABS(*info.avg_spc)
          ENDIF


        ENDELSE
        IF info.hide_avg THEN BEGIN
          info.ifg_plot->HIDE,name='avg'
          info.spc_plot->HIDE,name='avg'
        ENDIF
      ENDIF

    ENDIF  ;points gt 0

    ;			endelse

    info.ifg_plot->SHOW
    IF info.autoscale_spc THEN info.spc_plot->AUTOSCALE,/y
    IF info.autoscale_ifg_y THEN info.ifg_plot->AUTOSCALE,/y
    info.spc_plot->SHOW

    SOLOIST_FTS_STATUS,info,'Scan completed.'
    if info.debug THEN SOLOIST_FTS_message,info,'Scan end: '+timestamp()

    ;write interferogram file
    IF info.debug THEN clock=tic('write files')
    IF info.scans_remaining EQ 1 THEN BEGIN
      IF info.fts_scan_mode EQ 'Step and Integrate' THEN BEGIN
        hk = rrcat_soloist_fts_housekeeping(info, simHK=info.simHK, simADC=info.simADC)
      ENDIF ELSE BEGIN
        hk = rrcat_soloist_fts_housekeeping(info, simHK=info.simHK, simADC=info.simADC, /NO_SAI)
      ENDELSE
      info.housekeeping = hk
      ;RRCAT_SOLOIST_FTS_update_hk_status,info
    ENDIF
    RRCAT_SOLOIST_FTS_WRITE_FILE,info
    ;write spectrum
    RRCAT_SOLOIST_FTS_WRITE_SPC,info
    IF info.debug THEN TOC,clock
    info.last_points = 0	;reset the last point counter to zero

    info.scans_remaining --

    ;increment file number
    number=info.number_field->GET_VALUE()+1
    IF number GT 9999 THEN number=0   ;roll over file number
    info.number_field->SET_VALUE,number
    RRCAT_SOLOIST_FTS_UPDATE_FILENAME,info
    WIDGET_CONTROL,info.tlb,set_uvalue=info
    ;    IF info.fts_metrology EQ 'Laser' THEN BEGIN
    ;      result=info.soloist->disable_pso(err=err)
    ;      if(SOLOIST_FTS_handle_soloist_error(info, err)) then return
    ;    ENDIF
    ;if more scans in sequence, start a new scan
    IF info.scans_remaining GT 0 THEN BEGIN
      RRCAT_SOLOIST_FTS_START_SCAN,info    ;PSO will remain enabled from last time.
      ;if this is triggered mode, then the DOUT 0 line will remain high.
    ENDIF ELSE BEGIN
      IF NOT info.simStage THEN result=info.soloist->DISABLE_PSO(err=err) ;disable PSO now that all scans are done.
      result=SOLOIST_FTS_HANDLE_SOLOIST_ERROR(info, err)
      SOLOIST_FTS_MESSAGE,info,'Scans Finished.'
      SOLOIST_FTS_MESSAGE,info,'Ready.'
      SOLOIST_FTS_SENSITIZE,info
      RRCAT_SOLOIST_FTS_sensitize,info, /STEPPER
      RRCAT_SOLOIST_FTS_SAVE_SETTINGS,info	;save the settings again to store the new file number..
      info.scanning = 0
      WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      IF info.scans_field->GET_VALUE() GT 1 THEN BEGIN
        ;write average interferogram and spectrum
        RRCAT_SOLOIST_FTS_WRITE_SPC,info,/avg
        RRCAT_SOLOIST_FTS_WRITE_FILE,info,/avg
      ENDIF

      PROFILER, /REPORT, output=prof
      print,info,prof

;      ;
;      ; 16 Aug 2019
;      ; Re-enable the stepper comms
;      ;
;      stepper_port = 'COM7'
;      stepper = rrcat_soloist_init_stepper_controller(stepperMotors=info.stepperMotors, port=stepper_port, baud=9600,data=8,parity='N',stop=1)
;      if not obj_valid(stepper) then begin
;        result=dialog_message('Could not create BC6D20 Stepper Controller object on port '+stepper_port+'!',/err,title='Connection Error')
;        obj_destroy, stepper
;        simStepper = 1
;        stepper_port = 'SIM'
;      endif
;      info.stepper = stepper
;      ;

      IF info.triggered THEN BEGIN
        ;This is the triggered mode, so now wait for another trigger pulse to start another scan sequence
        ;The triggered scans only stop if the abort button is hit.
        WIDGET_CONTROL,info.start_id,send_event={id:info.start_id, Top:info.tlb, handler:info.tlb, select:1}
      ENDIF
    ENDELSE  ;if the scan is finished

  ENDELSE
  RETURN
END