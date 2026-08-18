;+
; NAME:
;	RRCAT_SOLOIST_FTS_EVENT
;
; PURPOSE:
;	This is the main event handler for SOLOIST_FTS.pro. All events are handled by this
;	code first.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_EVENT, Event
;
; INPUTS:
;	Event:	The widget event
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, Jan 7 2018. From SOLOIST_FTS_EVENT.pro
;   17 May 2018 (TRF): Changed Michelson/MP to Mid Infrared/Far Infrared
;   04 Jul 2019 (TRF): Restart HK timer if motor is already at the limit
;   05 Jul 2019 (TRF): Use the No_Copy keyword for the info block.
;   07 Jul 2019 (TRF): Remove No_Copy keyword for the info block.
;   08 Jul 2019 (TRF): Update housekeep at the start of a scan.
;   12 Jul 2019 (TRF): Step and integrate is now just slow scanning
;   12 Jul 2019 (TRF): Removed START_LW
;   30 Jul 2019 (TRF): Checks to see if info.directory exists and if it does not, creates it.
;   02 Aug 2019 (TRF): Use RRCAT_SOLOIST_FTS_ADC_DOUT
;   08 Aug 2019 (TRF): Check all peripherals during a normal HK update
;   16 Aug 2019 (TRF): Disable stepper controller comms when starting a set of scans
;   29 Aug 2019 (TRF): Remove disabling of stepper comms at the start of scans
;   30 Aug 2019 (TRF): Fixed the sequence of setting the stepper timer to avaoid multiple events
;   12 Sep 2019 (TRF): Reintroduce proper step and integrate
;-
;TODO- allow resolution in steps of .0001 instead of only .001

pro check_resolution,info

  sampling = soloist_fts_get_sampling(info) ;PSO interval in mm stage travel

  ;include acceleration/deceleration in travel calculation!!
  speed = info.speed_field->get_value()
  ramp_up_distance=speed^2/(2*info.acceleration) > (10*sampling) ;  go at least ten samples beyond the start of the interferogram.
  ramp_down_distance=speed^2/(2*info.acceleration)  ;also go speed^2/(2*accel) beyond end of interferogram to ensure stage isn't decelerating!

  nyquist=soloist_fts_get_nyquist(info)  ;nyquist in cm-1
  speed = info.speed_field->get_value()
  case info.freq_units of
    'ghz':nyquist=wn2ghz(nyquist)
    'wn':
    'hz':nyquist=nyquist*speed
    else:message,'Unhandled frequency units!',/cont
  endcase

  ;get the resolution
  resolution = info.resolution_field->get_value()  ;in current units

  ;n_buffers = floor(info.max_travel/(info.buffer*sampling))-1		;leave one spare buffers worth of travel at the end, to ensure that the last buffer gets filled.

  ;calculate maximum single sided travel in mm stage travel
  if info.symmetrical then begin
    md= abs(info.zpd - info.min_travel - ramp_up_distance) < abs(info.max_travel - info.zpd - ramp_down_distance)	;limited by the min and max stage travel
  endif else begin
    md=abs(info.max_travel - info.zpd - ramp_down_distance)		;limited by the max stage travel only, the double sided travel is checked elsewhere
  endelse
  ;TODO- this is wasteful. Find a better way to ensure last buffer is filled
  max_ss_dist = md - (info.buffer*sampling)

  ;	min_res=1.21/(2*(2*info.max_travel)) + 0.0005		;add 1/2 lsd to be sure field value is bigger than the limit
  if info.FTS_Type eq 'MZ' then mult=4. else mult=2.
  min_res=1.21/(2*(mult*max_ss_dist/10.)) + 0.0005
  min_res=round(min_res*1000)/1000. ;in cm-1
  case info.freq_units of
    'ghz':begin
      min_res=wn2ghz(min_res)
      txt=' GHz'
    end
    'wn':begin
      txt=' cm-1'
    end
    'hz':begin
      min_res=min_res*speed
      txt=' Hz'
    end
    else:message,'Unhandled frequency units!',/cont
  endcase
  max_res=nyquist/2.    ; in current units

  if resolution gt max_res then begin
    result=dialog_message(['Resolution is too low for current Nyquist.',$
      'Select a resolution smaller than '+strtrim(string(max_res,format='(f0.3)'),2)+txt+' or change the Nyquist.'],$
      /info, title='Parameter Error', dialog_parent=info.tlb)
  endif

  if resolution lt min_res then begin
    result=dialog_message(['Resolution is too high for stage travel and/or buffer length and/or acceleration.',$
      'Select a resolution larger than '+strtrim(string(ceil(min_res*1000)/1000.,format='(f0.3)'),2)+txt+'.'],/info, $
      title='Parameter Error', dialog_parent=info.tlb)
  endif

  ;since the input field will round to 3 decimal places, calculate the limits at the 3rd decimal.
  resolution = ceil(min_res*1000)/1000. > resolution < floor(max_res*1000)/1000.
  info.resolution_field->set_value,resolution
end

pro check_speed,info
  ;Check that the speed, detector response, and max signal frequency are compatible.
  ;the speed field is in cm/s OPD. Remember that the Soloist commands are in mm MPD.
  ;	v_opd=f/nyq
  speed = info.speed_field->get_value()
  if speed gt 10 and info.debug then soloist_fts_message,info,'Stage speed must be less than 50mm/s'
  speed = speed < 10.	;limit to 10 cm/s opd (50mm/sec mechanical)

  if speed gt info.freq_resp/info.max_freq then begin
    result=dialog_message(['Speed is too fast for maximum frequency of interest and detector time constant.',$
      'Select a speed less than '+strtrim(string(info.freq_resp/info.max_freq,format='(F6.3)'),2)+' cm/s or change the maximum frequency.'],$
      /info, title='Parameter Error', dialog_parent=info.tlb)
  endif

  speed = 0.001 > speed < info.freq_resp/info.max_freq  ;limit to 0.01mm/sec minimum

  ;now make sure that the speed isn't so fast as to make the buffer size too small
  ;note that the MC1808X doens't use buffers in the same way as the DT models do.

  if info.ADC_model ne 'MC1808X' then begin
    sampling = soloist_fts_get_sampling(info) ;PSO interval in mm stage travel
    if info.FTS_Type eq 'MZ' then mult=4. else mult=2.
    buffer_rate = speed/mult*10./(info.buffer*sampling)
    ;  max_rate = 2.5 ;at least 0.4 sec per buffer
    max_rate = 25. ;note that the DT7816 can handle high buffer rates, limited by the bandwidth required for dumping
    ;multiple buffers while the system catches up.
    if buffer_rate gt max_rate then begin   ;buffers being filled in less than 0.4 sec.
      result=dialog_message(['Speed is too fast for buffer length.',$
        'Select a speed less than '+strtrim(string(max_rate*info.buffer*sampling*mult/10.,format='(F6.3)'),2)+' cm/s or increase the buffer length.'],$
        /info, title='Parameter Error', dialog_parent=info.tlb)
    endif

    speed = 0.001 > speed < max_rate*info.buffer*sampling*mult/10.

  endif

  speed = floor(speed*1000)/1000.	;make sure it has the right number of significant digits

  info.speed_field->set_value,speed
end

pro check_scans,info
  scans = 1 > info.scans_field->get_value() < 999
  info.scans_field->set_value,scans
end

;convert frequency units
function convert_f,data,old_freq,new_freq,v_opd
  case old_freq of
    'wn':begin
      case new_freq of
        'ghz':return,wn2ghz(data)
        'hz':return,data*v_opd
      endcase
    end
    'ghz':begin
      case new_freq of
        'wn':return,ghz2wn(data)
        'hz':return,ghz2wn(data)*v_opd
      endcase
    end
    'hz':begin
      case new_freq of
        'ghz':return,wn2ghz(data/v_opd)
        'wn':return,data/v_opd
      endcase
    end
    else:return,!null
  endcase
end

;change the plot axes and input field labels for new frequency units
pro change_freq,info,new_units

  if info.freq_units eq new_units then return
  speed = info.speed_field->get_value()

  if info.spc_plot->isContained('current') then begin
    prev=info.spc_plot->getData('current')
    new_freq=convert_f(prev[0,*],info.freq_units,new_units,speed)
    info.spc_plot->setData,'current',new_freq,prev[1,*]
  endif
  if info.spc_plot->isContained('avg') then begin
    prev=info.spc_plot->getData('avg')
    new_freq=convert_f(prev[0,*],info.freq_units,new_units,speed)
    info.spc_plot->setData,'avg',new_freq,prev[1,*]
  endif
  if info.spc_plot->isContained('file') then begin
    prev=info.spc_plot->getData('file')
    new_freq=convert_f(prev[0,*],info.freq_units,new_units,speed)
    info.spc_plot->setData,'file',new_freq,prev[1,*]
  endif

  case new_units of
    'wn':begin
      info.spc_plot->SetAxisProperty,xtitle='Wavenumber (cm!E-1!N)'
    end
    'ghz':begin
      info.spc_plot->SetAxisProperty,xtitle='Frequency (GHz)'
    end
    'hz':begin
      info.spc_plot->SetAxisProperty,xtitle='Approx. Audio Frequency (Hz)'
    end
    else:begin
    end
  endcase

  info.spc_plot->getAxisProperty,xrange=xrange
  info.spc_plot->setAxisProperty,xrange=convert_f(xrange,info.freq_units,new_units,speed)
  info.spc_plot->show

  case new_units of
    'ghz':label='(GHz)'
    'wn':label='(cm-1)'
    'hz':label='(Hz)'
  endcase

  info.max_freq_field->setProperty,title='Max. Signal Freq. '+label
  new_max=convert_f(info.max_freq,info.freq_units,new_units,speed)
  new_max=round(new_max*100)/100.
  info.max_freq_field->set_value,new_max
  resolution=info.resolution_field->get_value()
  new_res=convert_f(resolution,info.freq_units,new_units,speed)
  new_res=round(new_res*1000)/1000.
  info.resolution_field->set_value, new_res
  info.resolution_field->setProperty,title='Resolution '+label

  ;get current nyquist (in the wn units)
  ;assume the nyquist list has same length and order for all units.
  current_nyquist=SOLOIST_FTS_GET_NYQUIST(info,index=current_ind)

  ;set up Nyquist list in the new units.
  info.freq_units=new_units
  RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST,info,index=current_ind

  id=widget_info(info.tlb,find_by_uname='nyquist list label')
  widget_control,id,set_value='Nyquist '+label

  return
end

PRO rrcat_soloist_fts_Event, event

  Widget_Control, event.top, Get_UValue=info;, /No_Copy

  if event.id eq event.top then begin
    ;the event came from the TLB. Resize the plot object
    ysize=event.y > info.widget_min_ysize 	;limit ysize so that the buttons don't get clipped.
    xsize=event.x > info.widget_x_size*2 	;limit xsize so that the plots aren't too small.

    widget_control,event.id, xsize=xsize, ysize=ysize
    info.ifg_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.spc_plot->SetProperty, xsize=xsize-info.widget_x_size, ysize=(ysize-info.widget_y_size)/2
    info.ifg_plot->show
    info.spc_plot->show
    return
  endif

  Widget_Control, event.id, Get_UValue=thisEvent

  CASE thisEvent OF
    'ABORT':begin
      SOLOIST_FTS_MESSAGE,info,'Scan aborted.'
      ;stop stage
      WIDGET_CONTROL,info.scan_toggle_timer_base, timer=-1
      if not info.simStage then result=info.soloist->abort(err=err)
      ;stop ADC
      if not info.simADC then result=SOLOIST_FTS_ADC_stop(model=info.adc_model,obj=info.adc_obj)
      info.scanning=0

      result=dialog_message('Scan has been aborted.',/info, title='Scan Aborted', dialog_parent=info.tlb)

      ;home stage
      SOLOIST_FTS_status,info,'Returning Home...'
      ;move stage to start (home takes too long)
      SOLOIST_FTS_track_move,info,0,speed=info.home_speed,err=err

      if err eq '' then SOLOIST_FTS_status,info,'Stage at home.'

      ;update plots
      if not info.simStage then begin
        opd=SOLOIST_FTS_pos_to_opd(info,info.soloist->Get_Pos(err=err)) ;current OPD position in cm
      endif else begin
        opd=SOLOIST_FTS_pos_to_opd(info,0)
      endelse

      SOLOIST_FTS_show_pos,info,opd
      info.last_points=0  ;reset the current point counter
      info.dio.scanning  = 0b
      bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
      IF info.debug THEN BEGIN
        SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to '+ STRING(bitVal)
      ENDIF
      if ~info.simADC then result=RRCAT_SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;set the FTS status to 'not waiting for trigger'
      info.abort=1
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
      SOLOIST_FTS_SENSITIZE,info
      if info.debug NE 0 THEN RRCAT_SOLOIST_FTS_SENSITIZE,info, /STEPPER
      IF info.fts_scan_mode EQ 'Step and Integrate' THEN BEGIN
        RRCAT_SOLOIST_FTS_SENSITIZE,info, /SAI
      ENDIF
    end
    'ABOUT':begin
      filename = Filepath(Root_Dir=ProgramRootDir(), Subdirectory='help', 'about_soloist_fts.txt')
      if filename eq '' then begin
        SOLOIST_FTS_MESSAGE,info,'Help directory not found!'
      endif else begin
        openr,lun,filename,/get
        text=''
        s=''
        while not(eof(lun)) do begin
          readf,lun,s
          text=[text,s]
        endwhile
        free_lun,lun
        b=widget_base(/col,group_leader=info.tlb,tlb_frame_attr=1,title='About SOLOIST FTS')
        t=widget_text(b,value=text,/wrap,xsize=75,ysize=n_elements(text)+1)
        widget_control,b,/real,/show
      endelse
    end
    'ACCELERATION':begin
      x=dialog_message('WARNING! Changing this value can risk damage to the stage!')
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter default acceleration (mm/s^2):',xsize=3,$
        decimal=1,/positive,value=info.acceleration)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        val=x->get_value()
        info.acceleration = val
        widget_control,b,/dest

        if info.simStage eq 0 then begin
          result=info.Soloist->SET_PARAMETER( 'DefaultRampRate',info.acceleration, err=err)
          if result eq 0 then begin
            SOLOIST_FTS_MESSAGE,info,'Error setting acceleration: '+err
            break
          endif
        endif

        SOLOIST_FTS_MESSAGE,info,'Acceleration set to: '+string(val,format='(f0.1)')+' mm/s^2 mechanical'
      endif
    end
    'ACK':begin
      if info.simStage eq 0 then begin
        result=info.soloist->fault_ack(err=err)		;acknowledge all faults and re-enable drive
      endif
    end
    'ADC_MODEL':begin
      models=['DT9803','DT9804','DT7816','MC1808X']
      ind=where(models eq info.adc_model)

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=cw_bgroup(b,models,/exclusive,/row,label_top='ADC Model',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      model_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          SOLOIST_FTS_MESSAGE,info,'ADC model set to: '+strtrim(info.adc_model,2)
          result=soloist_fts_init_adc(info)
        end
        x:begin
          info.adc_model = ev.value
          goto, model_loop		;handle events until ok is hit.
        end
        0:begin  ;base destroyed
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in ADC_MODEL'
        end
      endcase
    end
    'ADC_RANGE':begin
      case info.adc_model of
        'MC1808X':begin
          gains=[1,2]
          ranges=['10 V','5 V']
          info.gain=info.gain < 2   ;cap at 2 in case settings are from different ADC model.
        end
        else:begin
          gains=[1,2,4,8]
          ranges=['10 V','5 V','2.5 V','1.25 V']
        end
      endcase

      ind=where(gains eq info.gain)
      b=widget_base(group_leader=event.top,/col,/base_align_center,/modal,title='RRCAT_SOLOIST_FTS Settings',xsize=200)
      b2=widget_base(b,/row)
      id = widget_label(b2,value='Set ADC Range +/-')
      gain_id = widget_combobox(b2, value=ranges)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      widget_control,gain_id,SET_COMBOBOX_SELECT=ind
      gain_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok:begin
          text=widget_info(gain_id,/combobox_gettext)
          ind=where(ranges eq text)
          info.gain=(gains)[ind]
          SOLOIST_FTS_MESSAGE,info,'ADC range set to: '+text
          widget_control,b,/dest
          result=rrcat_soloist_fts_init_adc(info)   ;reset the adc
        end
        gain_id:begin
          goto,gain_loop
        end
        0:begin ;base destroyed
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in ADC_GAIN'
        end
      endcase
    end
    'ADC_TRIGGER':begin
      opt=['External TTL','Internal Clock']
      if info.clock_source eq 0 then ind=0 else ind=1

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=cw_bgroup(b,opt,/exclusive,/row,label_top='ADC Trigger',/frame,set_value=ind,/return_index)
      clock_freq_field=fsc_inputfield(b,/double,title='Internal Clock Rate (Hz)',xsize=9,decimal=4,/positive,value=info.clock_freq)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      clock_id=clock_freq_field->getID()
      trigger_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          SOLOIST_FTS_MESSAGE,info,'ADC trigger set to: '+strtrim(opt[info.clock_source],2)
          info.clock_freq = 1000. < clock_freq_field->get_value() > 0
          SOLOIST_FTS_MESSAGE,info,'ADC clock frequency: '+strtrim(info.clock_freq,2)
          widget_control,b,/dest
          result=rrcat_soloist_fts_init_adc(info)
        end
        x:begin
          info.clock_source = ev.value
          goto, trigger_loop		;handle events until ok is hit.
        end
        clock_id:begin
          freq = 1000. < clock_freq_field->get_value() > 0
          clock_freq_field->set_value,freq
        end
        0:begin ;base destroyed
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in ADC_TRIGGER'
        end
      endcase
    end
    'ADDRESS':begin
      SOLOIST_FTS_NETWORK,info
      widget_control,info.tlb,get_uvalue=info	;get the info block with the new settings.
    end
    'ASCII':begin
      SOLOIST_FTS_WRITE_ASCII		;prompt for files and convert to ascii
    end
    'AUTO_IFG_X':begin
      widget_control,event.id,set_value='Lock IFG X Axis',set_uvalue='LOCK_IFG_X'
      info.autoscale_ifg_x=1
    end
    'AUTO_IFG_Y':begin
      widget_control,event.id,set_value='Lock IFG Y Axis',set_uvalue='LOCK_IFG_Y'
      info.autoscale_ifg_y=1
    end
    'AUTO_SPC_Y':begin
      widget_control,event.id,set_value='Lock SPC Y Axis',set_uvalue='LOCK_SPC_Y'
      info.autoscale_spc=1
    end
    'BUFFER':begin
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter sample buffer length:',xsize=4,decimal=0,	value=info.buffer)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        buffer=1 > x->get_value() < 64000    ;make it at least 64 points long
        ;buffer -= buffer mod 32 ;make it an integer multiple of 32 points
        x->set_value,buffer
        info.buffer = buffer
        SOLOIST_FTS_MESSAGE,info,'ADC buffer set to: '+string(buffer,format='(f0.1)')+' points'
        if info.ADC_model ne 'MC1808X' then begin  ;MC1808X doesn't have an internal adjustable buffer. Just use buffer size for plot updates.
          result=soloist_fts_init_adc(info)		;reset the adc
        endif
        widget_control,b,/dest
      endif

      check_resolution,info
      check_speed,info
    end
    'CHOPPER_CONNECT': begin
      IF OBJ_VALID(info.chopper) THEN BEGIN
        OBJ_DESTROY, info.chopper
        info.simChopper = 1
        chopper_port = 'SIM'
        WIDGET_CONTROL, info.chopper_port_field, SET_VALUE=chopper_port
      ENDIF ELSE BEGIN
        chopper_port = 'COM6'
        info.chopper = rrcat_soloist_init_chopper_controller(port=chopper_port, baud=115200,data=8,parity='N',stop=1)
        ;
        info.simChopper = 0
        if not obj_valid(info.chopper) then begin
          result=dialog_message('Could not create MC2000B Chopper Controller object!',/err,title='Software Error')
          info.simChopper=1
          chopper_port = 'ERROR'
        endif else begin
          if info.fts_scan_mode EQ 'Step and Integrate' then begin
            RRCAT_SOLOIST_FTS_SENSITIZE, info, /CHOPPER
          endif
        endelse
        WIDGET_CONTROL, info.chopper_port_field, SET_VALUE=chopper_port
      ENDELSE
    end
    'CHOPPER_ENABLE':begin
      ; Pause the hk updates.
      ;help, event, /str
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      info.chopper_enable=event.select
      ;help, event, /str
      ;print, 'Enable select ' + STRTRIM(info.chopper_enable, 2)
      ;
      IF info.simChopper EQ 0 THEN BEGIN
        IF info.chopper_enable EQ 0 THEN BEGIN
          retStr = info.chopper->disable()
        ENDIF
        IF info.chopper_enable EQ 1 THEN BEGIN
          retStr = info.chopper->enable()
        ENDIF
        ;print, 'Enable cmd ' + retStr
        SOLOIST_FTS_status,info,retStr
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CHOPPER_BLADE':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      chop_blade_index = rrcat_soloist_convert_blade_index(event.index, /SELECT)
      info.chop_blade_index = chop_blade_index
      ;STOP
      rrcat_soloist_update_chopper_blade_fields, info, info.chop_blade_index
      ;
      IF info.simChopper EQ 0 THEN BEGIN
        ; STOP
        retStr = info.chopper->setBlade(info.chop_blade_index)
        SOLOIST_FTS_status,info,retStr
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CHOPPER_CYCLE':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      cycle = info.cycle_field_chop->get_value()
      if string(cycle) NE 'NULLVALUE' THEN BEGIN
        ;
        IF info.simChopper EQ 0 THEN BEGIN
          retStr = info.chopper->setOnCycle(cycle)
          SOLOIST_FTS_status,info,retStr
        ENDIF
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CHOPPER_FREQ':begin
      ; Pause the hk updates.
      ;help, event, /str
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      freq = info.freq_field_chop->get_value()
      if string(freq) NE 'NULLVALUE' THEN BEGIN
        ;
        IF info.simChopper EQ 0 THEN BEGIN
          retStr = info.chopper->setFreq(freq)
          SOLOIST_FTS_status,info,retStr
        ENDIF
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CHOPPER_PHASE':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      phase = info.phase_field_chop->get_value()
      if string(phase) NE 'NULLVALUE' THEN BEGIN
        ;
        IF info.simChopper EQ 0 THEN BEGIN
          retStr = info.chopper->setPhase(phase)
          SOLOIST_FTS_message,info,retStr
        ENDIF
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CHOPPER_OUTPUT':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      info.chopper_output_index = event.value

      IF info.simChopper EQ 0 THEN BEGIN
        retStr = info.chopper->setReference(info.chopper_output_index)
        SOLOIST_FTS_message,info,retStr
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CHOPPER_REFERENCE':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      info.chopper_ref_output_index = event.value
      IF info.simChopper EQ 0 THEN BEGIN
        retStr = info.chopper->setRefOutput(info.chopper_ref_output_index)
        SOLOIST_FTS_message,info,retStr
      ENDIF
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'CLEAR_FILE':begin
      info.ifg_plot->delete,name='file'
      info.ifg_plot->show
      info.spc_plot->delete,name='file'
      info.spc_plot->show
    end
    'COMMENT':begin
      ;limit string to 80 characters.
      str=info.comment_field->get_value()
      if strlen(str) gt 80 then begin
        str=strmid(str,0,80)
        info.comment_field->set_value,str
      endif
    end
    'DET_SAMPLES':begin
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter number of samples to acquire at each point (Step and Integrate mode only):',xsize=4,decimal=0, value=info.det_samples)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        x->set_value,det_samples
        info.det_samples = det_samples
        SOLOIST_FTS_MESSAGE,info,'Number of samples set to: '+string(det_samples,format='(I)')
        widget_control,b,/dest
      endif
    end
    'DETECTOR_TYPE':begin
      det_types=['HEB','TES','MCT','Pyro-1','Pyro-2']
      ind=where(det_types eq info.det_type)

      b=widget_base(group_leader=event.top,/col,/modal,title='Detector Settings')
      x=cw_bgroup(b,det_types,/exclusive,/row,label_top='Detector',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      det_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          SOLOIST_FTS_MESSAGE,info,'Detector set to: '+strtrim(info.det_type,2)
        end
        x:begin
          info.det_type = ev.value
          goto, det_loop    ;handle events until ok is hit.
        end
        0:begin  ;base destroyed
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in DET_TYPE'
        end
      endcase
      id=widget_info(info.tlb,find_by_uname='det_type')
      widget_control,id,set_value=STRTRIM(info.det_type, 2)
      IF info.simStepper EQ 0 THEN BEGIN
        rrcat_set_det_type, info, info.optics, info.det_type
      endif
      IF info.fts_scan_mode EQ 'Step and Integrate' THEN BEGIN
        IF info.simLia EQ 0 THEN BEGIN
          rc = RRCAT_SOLOIST_FTS_load_lia_settings(info)
          RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
        endif
      ENDIF
      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'DIRECTORY':begin
      result=dialog_pickfile(path=info.directory,/directory,title='Choose a directory for interferogram files')
      IF FILE_TEST(result) NE 1 THEN BEGIN
        FILE_MKDIR, result
      ENDIF
      if result ne '' then info.directory=result
    end
    'DOUBLE_SIDED':begin
      ds=info.ds_field->get_value() ;(cm opd)
      if info.FTS_Type eq 'MZ' then ds/=0.4 else ds/=0.2			;(mm MPD)
      ds = ds < (info.zpd - info.min_travel)
      if info.FTS_Type eq 'MZ' then ds*=0.4 else ds*=0.2			;(cm OPD)
      info.ds_field->set_value,ds
    end
    'ENCODER':begin
      Encoder=['Primary','Auxiliary','MXH']
      ind=where(Encoder eq info.encoder)

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=cw_bgroup(b,encoder,/exclusive,/row,label_top='Encoder Channel',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      type_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          SOLOIST_FTS_MESSAGE,info,'Soloist encoder channel set to: '+strtrim(info.encoder,2)
        end
        x:begin
          info.encoder = ev.value
          goto, type_loop		;handle events until ok is hit.
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in ENCODER'
        end
      endcase
    end
    'FREQ':begin
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter detector frequency response (Hz):',xsize=4,$
        decimal=1,value=info.freq_resp)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        freq=x->get_value()
        info.freq_resp = freq
        widget_control,b,/dest
        check_speed,info
      endif
    end
    'FREQ_UNITS':begin
      units=['wn','ghz','hz']
      ind=where(units eq info.freq_units)

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=cw_bgroup(b,['cm-1','GHz','Hz (audio)'],/exclusive,/row,label_top='Frequency Units',$
        /no_release,/frame,set_value=ind,/return_index)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      freq_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          SOLOIST_FTS_MESSAGE,info,'Frequency units set to: '+strtrim(info.freq_units,2)
        end
        x:begin
          change_freq,info,units(ev.value)
          goto, freq_loop    ;handle events until ok is hit.
        end
        0:begin ;must have closed the window
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in FREQ_UNITS'
        end
      endcase
    end
    'FTS_METROLOGY':begin
      types=['PSO','Laser']
      ind=where(types eq info.fts_metrology)

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=cw_bgroup(b,types,/exclusive,/row,label_top='FTS Metrology',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      metrology_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          SOLOIST_FTS_MESSAGE,info,'FTS Metrology set to: '+strtrim(info.fts_metrology,2)
        end
        x:begin
          info.fts_metrology = ev.value
          goto, metrology_loop    ;handle events until ok is hit.
        end
        0:begin ;must have closed the window
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in FTS_METROLOGY'
        end
      endcase
      id=widget_info(info.tlb,find_by_uname='fts_metrology')
      widget_control,id,set_value=STRTRIM(info.fts_metrology, 2)
      IF info.simADC EQ 0 THEN BEGIN
        IF info.fts_metrology EQ 'PSO' THEN BEGIN
          info.nyquist_list = info.nyquist_list_pso
          info.sampling_list = info.sampling_list_pso
          info.dio.metrology = 0b
          ;******************
          ;Re-Initialize Soloist for PSO metrology
          ;******************
          soloist_connected=rrcat_soloist_fts_connect(info)
        ENDIF ELSE BEGIN
          info.nyquist_list = info.nyquist_list_laser
          info.sampling_list = info.sampling_list_laser
          info.dio.metrology = 1
          ;******************
          ;Re-Initialize Soloist for Laser metrology
          ;******************
          soloist_connected=rrcat_soloist_fts_connect(info, /WINDOW)
        ENDELSE
        WIDGET_CONTROL, info.nyquist_id, SET_VALUE = STRING(*(info.nyquist_list),format='(f8.2)')
        bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
        IF info.debug THEN BEGIN
          SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to '+ STRING(bitVal)
        ENDIF
        result=RRCAT_SOLOIST_FTS_ADC_DOUT(bitval,model=info.adc_model,obj=info.adc_obj)
      ENDIF
    end
    'FTS_SCAN_MODE':begin
      types=['Rapid Scan','Step and Integrate']
      ind=where(types eq info.fts_scan_mode)

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Scanning Mode')
      x=cw_bgroup(b,types,/exclusive,/row,label_top='FTS Scanning Mode',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      fts_scan_mode_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST,info
          SOLOIST_FTS_MESSAGE,info,'FTS Scanning Mode set to: '+strtrim(info.fts_scan_mode,2)
        end
        x:begin
          info.fts_scan_mode = ev.value
          goto, fts_scan_mode_loop    ;handle events until ok is hit.
        end
        0:begin ;must have closed the window
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in FTS_SCAN_MODE'
        end
      endcase
      id=widget_info(info.tlb,find_by_uname='fts_scan_mode')
      rrcat_soloist_change_fts_scan_mode, info, info.fts_scan_mode
      widget_control,id,set_value=STRTRIM(info.fts_scan_mode, 2)
    end
    'FTS_TAB_SELECT':begin ; FTS_SELECT has been selected
      RRCAT_SOLOIST_FTS_save_settings,info
      ;rrcat_enable_fts_tab, info, event.tab
      IF event.tab EQ 2 THEN BEGIN
        selected_motor = info.selected_motor
        selected_motor_index = info.selected_motor_index
        rrcat_update_stepper_motor_fields, selected_motor_index, info
      ENDIF ELSE BEGIN
        id=widget_info(info.tlb,find_by_uname='fts_type')
        widget_control,id,set_value=STRTRIM(info.fts_selected, 2)
      ENDELSE
    end
    'FTS_SELECT':begin
      types=['Michelson','Martin-Puplett']
      ind=where(types eq info.fts_selected)

      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=cw_bgroup(b,types,/exclusive,/row,label_top='FTS Type',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      encoder_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST,info
          SOLOIST_FTS_MESSAGE,info,'FTS type set to: '+strtrim(info.fts_selected,2)
        end
        x:begin
          info.fts_selected = ev.value
          goto, encoder_loop		;handle events until ok is hit.
        end
        0:begin ;must have closed the window
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in FTS_TYPE'
        end
      endcase
      id=widget_info(info.tlb,find_by_uname='fts_type')
      widget_control,id,set_value=STRTRIM(info.fts_selected, 2)
      IF info.fts_selected EQ 'Michelson' THEN BEGIN
        info.zpd = info.zpd_sw
      ENDIF
      IF info.fts_selected EQ 'Martin-Puplett' THEN BEGIN
        info.zpd = info.zpd_lw
      ENDIF

      IF info.simStepper EQ 0 THEN BEGIN
        rrcat_set_fts_type, info, info.fts_selected
      endif
      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'HELP':begin
      soloist_fts_help
    end
    'HIDE_AVERAGE':begin
      widget_control,event.id,set_value='Show Average',set_uvalue='SHOW_AVERAGE'
      info.ifg_plot->hide,name='avg'
      info.spc_plot->hide,name='avg'
      info.hide_avg=1
    end
    'HIDE_CURRENT':begin
      widget_control,event.id,set_value='Show Current',set_uvalue='SHOW_CURRENT'
      info.ifg_plot->hide,name='current'
      info.spc_plot->hide,name='current'
      info.hide_current=1
    end
    'HK_REFRESH':begin
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      b=widget_base(group_leader=event.top,/col,/modal,title='SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter number of seconds between housekeep status updates:',xsize=4,decimal=0, value=info.hk_refresh)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        hk_refresh = x->get_value()
        info.hk_refresh = hk_refresh
        SOLOIST_FTS_MESSAGE,info,'Housekeep status will be updated every '+string(hk_refresh,format='(I)')+' seconds.'
        widget_control,b,/dest
      endif
      WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    end
    'HK_TIMER':begin
      IF info.debug THEN clock=tic('HK Update')
      hk = rrcat_soloist_fts_housekeeping(info, simHK = info.simHK, simADC=info.simADC)
      info.housekeeping = hk
      ;      hk = rrcat_soloist_fts_housekeeping(info, simHK = info.simHK, simADC=info.simADC, NO_SAI=NO_SAI)
      ;      info.housekeeping = hk
      ;      RRCAT_SOLOIST_FTS_update_hk_status, info, NO_SAI=NO_SAI
      WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      IF info.debug THEN TOC,clock
    end
    'HOME':begin
      ;home stage
      if info.simStage eq 0 then begin
        widget_control,/hourglass
        result=info.soloist->home(/block,err=err)
        widget_control,hourglass=0
        ;result = SOLOIST_FTS_handle_soloist_error(info, err)
        if err ne '' then begin
          SOLOIST_FTS_message,info, 'Soloist error: '+strtrim( err )
          SOLOIST_FTS_MESSAGE,info,'Home Failed!'
          break
        end

        opd=SOLOIST_FTS_pos_to_opd(info,info.soloist->get_pos(err=err))	;current OPD position in cm
      endif else begin
        opd=SOLOIST_FTS_pos_to_opd(info,0)
      endelse

      SOLOIST_FTS_show_pos,info,opd
      SOLOIST_FTS_MESSAGE,info,'Stage Homed.'
      SOLOIST_FTS_MESSAGE,info,'Ready.'
    end
    'HOME_SPEED':begin
      x=dialog_message('WARNING! Changing this value can risk damage to the stage!')
      b=widget_base(group_leader=event.top,/col,/modal,title='SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter home speed (mm/s mechanical):',xsize=3,$
        decimal=1,/positive,value=info.home_speed)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        val=x->get_value()
        info.home_speed = val
        widget_control,b,/dest
        SOLOIST_FTS_MESSAGE,info,'Home speed set to: '+string(val,format='(f0.1)')+' mm/s mechanical'
      endif
    end
    'IFG_MOUSE':BEGIN
      info.ifg_plot->mousemenu
    END
    'IFG Plot Event': BEGIN
      case TAG_NAMES( event, /STRUCTURE_NAME) of
        'BGPLOTEVENT' : begin

        end
        else : stop
      endcase
    END
    'LIA_CONNECT': begin
      IF OBJ_VALID(info.lia) THEN BEGIN
        OBJ_DESTROY, info.lia
        info.simLia = 1
        lia_port = 'SIM'
        WIDGET_CONTROL, info.lia_port_field, SET_VALUE=lia_port
      ENDIF ELSE BEGIN
        lia_port = 'COM9'
        info.lia = rrcat_soloist_init_lia(port=lia_port, baud=9600,data=8,parity='N',stop=1)
        info.simLia = 0
        if not obj_valid(info.lia) then begin
          result=dialog_message('Could not create SR830 Lock-in Amplifier object!',/err,title='Connection Error')
          info.simLia = 1
          lia_port = 'ERROR'
        endif else begin
          if info.fts_scan_mode EQ 'Step and Integrate' then begin
            RRCAT_SOLOIST_FTS_SENSITIZE, info, /LIA
          endif
        endelse
        WIDGET_CONTROL, info.lia_port_field, SET_VALUE=lia_port
      ENDELSE
    end
    'LIA_SAVE_SETTINGS':begin
      rrcat_soloist_fts_save_lia_settings, info
    end
    'LOAD_SETTINGS':begin
      file=dialog_pickfile(file=ProgramRootDir()+'rrcat_soloist_fts_settings.xml', filter='*.xml', /fix_filter, $
        title='Select a settings file to read...',/must_exist)
      if file eq '' then break
      result=rrcat_soloist_fts_load_settings(info,file)
      if result eq 0 then begin
        x=dialog_message(['Error loading settings file!','Check parameters carefully!'],/err,dialog_parent=info.tlb)
      endif
    end
    'LOCK_IFG_X':begin
      widget_control,event.id,set_value='Autoscale IFG X Axis',set_uvalue='AUTO_IFG_X'
      info.autoscale_ifg_x=0
    end
    'LOCK_IFG_Y':begin
      widget_control,event.id,set_value='Autoscale IFG Y Axis',set_uvalue='AUTO_IFG_Y'
      info.autoscale_ifg_y=0
    end
    'LOCK_SPC_Y':begin
      widget_control,event.id,set_value='Autoscale SPC Y Axis',set_uvalue='AUTO_SPC_Y'
      info.autoscale_spc=0
    end
    'LOG':begin	;toggle the debug logging
      if !journal ne 0 then journal ;if a log file is open, close it
      if info.debug then begin	;already in debug mode
        info.debug=0
        widget_control,event.id,set_value='Enable Log'
      endif else begin	;turn on debug mode
        ;make a new log file.
        caldat,systime(/jul),mo,d,y,h,m,s
        journal,info.directory+'rrcat_soloist_fts_log_'+string(y,mo,d,h,m,s,format='(I4,I2.2,I2.2,"_",I2.2,I2.2,I2.2)')+'.txt'
        info.debug=1
        widget_control,event.id,set_value='Disable Log'
      endelse
    end
    'LOG_SPC':begin	;set logarithmic SPC scale
      widget_control,event.id,set_value='Linear Spectral Intensity',set_uvalue='LIN_SPC'
      info.spc_plot->getAxisProperty,yrange=yrange
      ;make sure existing plot range isn't negative
      yrange[0] = yrange[0] > 1e-9
      yrange[1] = yrange[1] > 1e-8
      info.spc_plot->setAxisProperty,yrange=yrange
      info.spc_plot->setAxisProperty,/ylog
      info.spc_plot->show
    end
    'LIN_SPC':begin	;set linear SPC scale
      widget_control,event.id,set_value='Log Spectral Intensity',set_uvalue='LOG_SPC'
      info.spc_plot->setAxisProperty,ylog=0
      info.spc_plot->show
    end
    'MAX_FREQ':begin
      if size(*event.value,/type) eq 0 then val = 0 $	;if no value is in the field, set it to 0
      else val = *(event.value)
      if info.freq_units eq 'wn' then begin
        number=10. > val < 2500.    ;limit to 10cm-1 on the low end, and 1um sampling on the high end (for Michelson)
        if number eq 10. or number eq 2500. then info.max_freq_field->set_value,number    ;reset field value if it is outside limits
      endif else begin
        val=ghz2wn(val)
        number=10. > val < 2500.    ;limit to 10cm-1 on the low end, and 1um sampling on the high end (for Michelson)
        if number eq 10. or number eq 2500. then info.max_freq_field->set_value,wn2ghz(number)  ;reset field value if it is outside limits
      endelse
      info.max_freq=number
      check_speed,info
    end
    'MAX_TRAVEL':begin
      x=dialog_message('WARNING! Changing this value can risk damage to the stage!')
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter maximum stage travel (mm mechanical):',xsize=5,$
        decimal=1,value=info.max_travel)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        val=x->get_value()
        info.max_travel = val
        widget_control,b,/dest
        SOLOIST_FTS_MESSAGE,info,'Max Travel set to: '+string(val,format='(f0.1)')+' mm'
      endif
    end
    'MIN_TRAVEL':begin
      x=dialog_message('WARNING! Changing this value can risk damage to the stage!')
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter minimum stage travel (mm mechanical):',xsize=3,$
        decimal=1,value=info.min_travel)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        val=x->get_value()
        info.min_travel = val
        widget_control,b,/dest
        SOLOIST_FTS_MESSAGE,info,'Min Travel set to: '+string(val,format='(f0.1)')+' mm'
      endif
    end
    'MEASUREMENT_TYPE':begin
      id=widget_info(event.top, FIND_BY_UNAME="MEASUREMENT_TYPE")
      widget_control, id, get_value=val
      info.measurement_type = info.measurement_types[val]
      SOLOIST_FTS_MESSAGE,info,'Measurement set to: '+info.measurement_type
      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'NULL':begin	;for widgets with meaningless events.
    end
    'NUMBER':begin
      if size(*event.value,/type) eq 0 then val = 0 $	;if no value is in the field, set it to 0
      else val = *(event.value)
      number=0 > val < 9999
      if number eq 0 or number eq 9999 then info.number_field->set_value,number	;reset the field if we trapped an out of range value

      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'NYQUIST':begin
      nyquist=(*info.nyquist_list)[event.index]
      ;check the speed, which might be incorrect now
      check_speed,info
      check_resolution,info
      speed = info.speed_field->get_value()
      case info.freq_units of
        'ghz':nyquist=wn2ghz(nyquist)
        'wn':
        'hz':nyquist=nyquist*speed
        else:message,'Unhandled frequency units!',/cont
      endcase
      info.spc_plot->setAxisProperty,xrange=[0,nyquist]
    end
    'OPEN':begin
      result=RRCAT_SOLOIST_FTS_READ_FILE(parent=info.tlb)
      ;{header:header,opd:opd,signal:signal}
      if size(result,/type) eq 8 then begin
        info.ifg_plot->delete,name='file'
        info.ifg_plot->add,result.opd,result.signal,color=[255,255,0],name='file'
        info.ifg_plot->autoscale
        info.ifg_plot->show

        ;calculate FFT  -SHOULD PROBABLY DO SOMETHING WITH THE ZPD LOCATION
        points=result.header.samples
        ;				nyquist=result.header.nyquist
        ;				wn=findgen(points/2+1)/(points/2.) * nyquist
        ;		;		spc=(abs(fft(data[0:points-1])))[0:points/2]
        ;				spc=(abs(fft(result.signal)))[0:points/2]

        ;need odd number of points.
        n=points + (points mod 2) -1
        fft_result=fft_to_spectrum((result.signal)[0:n-1]-mean((result.signal)[0:n-1]), (result.opd)[0:n-1], spc, wn)

        info.spc_plot->delete,name='file'

        speed = info.speed_field->get_value()
        case info.freq_units of
          'ghz':info.spc_plot->add,wn2ghz(wn),spc,color=[255,255,0],name='file'
          'wn':info.spc_plot->add,wn,abs(spc),color=[255,255,0],name='file'
          'hz':info.spc_plot->add,wn*speed,abs(spc),color=[255,255,0],name='file'
          else:message,'Unhandled frequency units!',/cont
        endcase
        info.spc_plot->autoscale
        info.spc_plot->show

      endif
    end
    'OPTICS_TYPE':begin
      optics_types=['Reflection','Transmission','Intermediate']
      ind=where(optics_types eq info.optics)

      b=widget_base(group_leader=event.top,/col,/modal,title='Mode Settings')
      x=cw_bgroup(b,optics_types,/exclusive,/row,label_top='Mode',/frame,set_value=ind,/return_name)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      optics_loop:
      ev=widget_event(b,bad_id=bad)
      case ev.id of
        ok: begin
          widget_control,b,/dest
          SOLOIST_FTS_MESSAGE,info,'Mode set to: '+strtrim(info.optics,2)
        end
        x:begin
          info.optics = ev.value
          goto, optics_loop    ;handle events until ok is hit.
        end
        0:begin  ;base destroyed
        end
        else:begin
          SOLOIST_FTS_MESSAGE,info,'Unhandled event in OPTICS_TYPE'
        end
      endcase
      id=widget_info(info.tlb,find_by_uname='optics_type')
      widget_control,id,set_value=STRTRIM(info.optics, 2)
      IF info.simStepper EQ 0 THEN BEGIN
        rrcat_set_optics_type, info, info.optics
        rrcat_set_det_type, info, info.optics, info.det_type
      ENDIF
      IF info.fts_scan_mode EQ 'Step and Integrate' THEN BEGIN
        IF info.simLia EQ 0 THEN BEGIN
          rc = RRCAT_SOLOIST_FTS_load_lia_settings(info)
          RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
        endif
      ENDIF
      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'PREFIX':begin
      ;limit to 12 characters
      str=info.prefix_field->get_value()
      if strlen(str) gt 12 then begin
        str=strmid(str,0,12)
        info.prefix_field->set_value,str
      endif
      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'PRINT' : begin
      ;create the printer object. This should normally be done at the main program level
      Printer = OBJ_NEW('IDLgrPrinter')
      Result = DIALOG_PRINTERSETUP(printer, DIALOG_PARENT=event.top)
      if result ne 0 then begin
        result = DIALOG_PRINTJOB(printer)
        if result ne 0 then begin
          info.ifg_plot->print,printer,/neg
          info.spc_plot->print,printer,/neg
        endif
      endif
      ;destroy the printer object. This should normally be done at the main program level
      ;or the printer will need to be configured each time.
      obj_destroy,printer
    end
    'QUIT': begin
      RRCAT_SOLOIST_FTS_save_settings,info
      Widget_Control, event.top, /Destroy
      return
    end
    'RANGE':begin
      nyquist=soloist_fts_get_nyquist(info)
      speed = info.speed_field->get_value()
      case info.freq_units of
        'ghz':nyquist=wn2ghz(nyquist)
        'wn':
        'hz':nyquist=nyquist*speed
        else:message,'Unhandled frequency units!',/cont
      endcase

      info.ifg_plot->setAxisProperty,xrange=SOLOIST_FTS_POS_TO_OPD(info,[info.min_travel,info.max_travel]),yrange=[-10,10]
      info.spc_plot->setAxisProperty,xrange=[0,nyquist]
      info.ifg_plot->show
      info.spc_plot->show
    end
    'RELAY_CONNECT': begin
      IF OBJ_VALID(info.relay) THEN BEGIN
        OBJ_DESTROY, info.relay
        info.simRelay = 1
        relay_port = 'SIM'
        WIDGET_CONTROL, info.relay_port_field, SET_VALUE=relay_port
      ENDIF ELSE BEGIN
        relay_port = 'COM8'
        info.relay = rrcat_soloist_init_relay(port=relay_port, baud=relay,data=8,parity='N',stop=1)
        ;relay=obj_new('kta223',port='COM1',baud=9600,data=8,parity='N',stop=1)
        info.simRelay = 0
        if not obj_valid(info.relay) then begin
          result=dialog_message('Could not create KTA223 Relay controller object!',/err,title='Connection Error')
          info.simRelay=1
          relay_port = 'ERROR'
        endif else begin
          if info.debug EQ 1 then begin
            RRCAT_SOLOIST_FTS_SENSITIZE, info, /RELAY
          endif
        endelse
        WIDGET_CONTROL, info.relay_port_field, SET_VALUE=relay_port
      ENDELSE
    end
    'RELAY_ENABLE':begin
      ;
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      old_relay_status = info.relay_status_vector
      WIDGET_CONTROL,info.enable_bgroup_relay, GET_VALUE=relay_status
      result = 'OK'
      IF old_relay_status[4] EQ 0 AND relay_status[4] EQ 1 THEN BEGIN
        result=dialog_message('You are about to turn on the Hg Source. Please ensure that the Hg Cooler is running.',/CANCEL, title='Hg Source Warning')
      ENDIF
      IF result NE 'Cancel' THEN BEGIN
        info.relay_status_vector = relay_status
        relay_state = rrcat_soloist_relay_state(info, relay_status)
        ;stop
        IF info.simRelay EQ 0 THEN BEGIN
          SOLOIST_FTS_MESSAGE,info,'Writing ' + STRTRIM(relay_state, 2) + ' to the relay'
          retVal = info.relay->writeRelays(relay_state)
          RRCAT_SOLOIST_UPDATE_RELAY_FIELDS, info
          rrcat_soloist_update_relay_status, info
          IF info.debug NE 0 THEN SOLOIST_FTS_STATUS,info, retVal
        ENDIF
      ENDIF
      ;
      ; Only reset the hk timer if we are not scanning
      ;
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'RESET ADC':begin
      if ~info.simADC then begin
        result=soloist_fts_init_adc(info)
        if result eq 1 then begin
          err=''
          if ~info.simStage then p=info.soloist->get_pos(err=err)
          if err eq '' || info.SimStage then widget_control,info.tab_base,sens=1	;resensitize control buttons
        endif
      endif
    end
    'RESET SOLOIST':begin
      if ~info.simStage then begin
        result=soloist_fts_connect(info)
        if result eq 1 then begin
          ;reset the ADC anyhow
          x=0
          if ~info.simADC then begin
            x=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
            x=SOLOIST_FTS_INIT_ADC(info)
          endif
          if x eq 1 || info.simADC then widget_control,info.tab_base,sens=1  ;resensitize control buttons
        endif
      endif
    end
    'RESOLUTION':begin
      check_resolution,info
    end
    'RT_TYPE':begin
      id=widget_info(event.top, FIND_BY_UNAME="RT_TYPE")
      widget_control, id, get_value=val
      info.rt_type = info.rt_types[val]
      SOLOIST_FTS_MESSAGE,info,'Measurement set to: '+info.rt_type
      RRCAT_SOLOIST_FTS_update_filename,info
    end
    'SAI_TIMER':begin
      RRCAT_SOLOIST_FTS_process_sai_timer,info
    end
    'SAVE_AVG':begin
      soloist_fts_write_spc,info,/avg
    end
    'SAVE_CURRENT':begin
      soloist_fts_write_spc,info
    end
    'SAVE_SETTINGS':begin
      file=dialog_pickfile(file=ProgramRootDir()+'rrcat_soloist_fts_settings.xml', filter='*.xml', /fix_filter, title='Select a filename for the settings...')
      if file eq '' then break
      rrcat_soloist_fts_save_settings,info,file
    end
    'SCANS':begin
      check_scans,info
    end
    'SHOW_AVERAGE':begin
      widget_control,event.id,set_value='Hide Average',set_uvalue='HIDE_AVERAGE'
      info.ifg_plot->reveal,name='avg'
      info.spc_plot->reveal,name='avg'
      info.ifg_plot->show
      info.spc_plot->show
      info.hide_avg=0
    end
    'SHOW_CURRENT':begin
      widget_control,event.id,set_value='Hide Current',set_uvalue='HIDE_CURRENT'
      info.ifg_plot->reveal,name='current'
      info.spc_plot->reveal,name='current'
      info.ifg_plot->show
      info.spc_plot->show
      info.hide_current=0
    end
    'SOURCE':begin
      str=info.source_field->get_value()
      if strlen(str) gt 80 then begin
        str=strmid(str,0,80)
        info.source_field->set_value,str
      endif
    end
    'SPC_MOUSE':BEGIN
      info.spc_plot->mousemenu
    END
    'SPC Plot Event': BEGIN
      case TAG_NAMES( event, /STRUCTURE_NAME) of
        'BGPLOTEVENT' : begin

        end
        else : stop
      endcase
    END
    'SPEED':begin
      check_speed,info
      ;update nyquist list if units are Hz
      result=SOLOIST_FTS_GET_NYQUIST(info, index=ind)
      RRCAT_SOLOIST_FTS_SET_NYQUIST_LIST,info,index=ind
    end
    ;    'START_LW': begin
    ;      RRCAT_SOLOIST_FTS_save_settings,info
    ;      info.abort=0
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      info.scanning=1
    ;      hk = rrcat_soloist_fts_housekeeping(info, simHK=info.simHK, simADC=info.simADC, /NO_SAI)
    ;      info.housekeeping = hk
    ;      RRCAT_SOLOIST_FTS_update_hk_status,info
    ;
    ;
    ;      IF info.fts_scan_mode EQ 'Step and Integrate' THEN info.samples_acquired=0
    ;
    ;      ;set up the buffer size, in case nyquist or speed has changed
    ;      result=RRCAT_SOLOIST_FTS_INIT_ADC(info)
    ;      if result ne 1 then begin
    ;        SOLOIST_FTS_MESSAGE,info,'ADC acquisition failed: '+strtrim(result,2)
    ;        SOLOIST_FTS_MESSAGE,info,'ADC status: '+strtrim(SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj),2)
    ;        result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
    ;        info.scanning=0
    ;        return
    ;      endif
    ;
    ;      ;get the number of scans to do
    ;      info.scans_remaining = info.scans_field->get_value()
    ;      ;delete the average plots
    ;      info.ifg_plot->delete,name=['avg']
    ;      info.spc_plot->delete,name=['avg']
    ;      *info.avg_ifg=!null
    ;      *info.avg_spc=!null
    ;
    ;      if info.triggered then begin
    ;        info.dio.scanning  = 0b
    ;        IF info.debug THEN BEGIN
    ;          SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to ', STRING(bitVal)
    ;        ENDIF
    ;        bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
    ;        if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;set the ADC output line low indicating FTS is ready for trigger. This should already be low.
    ;        ready=0
    ;        SOLOIST_FTS_status,info, 'Waiting for scan trigger..'
    ;        ;wait for the ADC trigger input if in triggered scan mode
    ;        while ready eq 0 do begin
    ;          ;check if abort was hit
    ;          result=widget_event(info.abort_id,/nowait)
    ;          if result.id ne 0 then begin
    ;            info.abort=1
    ;            info.dio.scanning  = 0b
    ;            IF info.debug THEN BEGIN
    ;              SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to ', STRING(bitVal)
    ;            ENDIF
    ;            bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
    ;            if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;the FTS status is not scanning.
    ;            break ;the abort button was hit.
    ;          endif
    ;          if ~info.simADC then begin
    ;            val=SOLOIST_FTS_ADC_DIN(model=info.adc_model,obj=info.adc_obj)  ;check the input lines
    ;            ready = val AND 1b  ;ready flag is on first input
    ;          endif else begin
    ;            ;no ADC in simulate mode, so start immediately
    ;            ready = 1
    ;          endelse
    ;        endwhile
    ;
    ;        if info.abort then begin
    ;          info.abort=0
    ;          break ;skip out of case if the abort was hit waiting for the ready flag
    ;        endif
    ;        SOLOIST_FTS_status,info, 'Scan triggered.'
    ;        ;now start the scan(s). The DOUT 0 line will be set high during scan.
    ;        IF info.fts_scan_mode EQ 'Rapid Scan' THEN RRCAT_SOLOIST_FTS_start_scan,info,/set_PSO
    ;        IF info.fts_scan_mode EQ 'Step and Integrate' THEN RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO
    ;
    ;      endif else begin
    ;        ;start the scan immediately
    ;        IF info.fts_scan_mode EQ 'Rapid Scan' THEN RRCAT_SOLOIST_FTS_start_scan,info,/set_PSO
    ;        IF info.fts_scan_mode EQ 'Step and Integrate' THEN RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO
    ;      endelse
    ;
    ;      ;reset the abort flag, in case the scan was aborted
    ;      info.abort=0
    ;
    ;    end
    ;    'START_SAI_LW': begin
    ;      RRCAT_SOLOIST_FTS_save_settings,info
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      info.abort=0
    ;      info.scanning=1
    ;      info.samples_acquired=0
    ;
    ;      ;set up the buffer size, in case nyquist or speed has changed
    ;      result=RRCAT_SOLOIST_FTS_INIT_ADC(info)
    ;      if result ne 1 then begin
    ;        SOLOIST_FTS_MESSAGE,info,'ADC acquisition failed: '+strtrim(result,2)
    ;        SOLOIST_FTS_MESSAGE,info,'ADC status: '+strtrim(SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj),2)
    ;        result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
    ;        info.scanning=0
    ;        return
    ;      endif
    ;
    ;      ;get the number of scans to do
    ;      info.scans_remaining = info.scans_field->get_value()
    ;      ;delete the average plots
    ;      info.ifg_plot->delete,name=['avg']
    ;      info.spc_plot->delete,name=['avg']
    ;      *info.avg_ifg=!null
    ;      *info.avg_spc=!null
    ;
    ;      if info.triggered then begin
    ;        info.dio.scanning  = 0b
    ;        bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
    ;        if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;set the ADC output line low indicating FTS is ready for trigger. This should already be low.
    ;        ready=0
    ;        SOLOIST_FTS_status,info, 'Waiting for scan trigger..'
    ;        ;wait for the ADC trigger input if in triggered scan mode
    ;        while ready eq 0 do begin
    ;          ;check if abort was hit
    ;          result=widget_event(info.abort_id,/nowait)
    ;          if result.id ne 0 then begin
    ;            info.abort=1
    ;            info.dio.scanning  = 0b
    ;            bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
    ;            if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;the FTS status is not scanning.
    ;            break ;the abort button was hit.
    ;          endif
    ;          if ~info.simADC then begin
    ;            val=SOLOIST_FTS_ADC_DIN(model=info.adc_model,obj=info.adc_obj)  ;check the input lines
    ;            ready = val AND 1b  ;ready flag is on first input
    ;          endif else begin
    ;            ;no ADC in simulate mode, so start immediately
    ;            ready = 1
    ;          endelse
    ;        endwhile
    ;
    ;        if info.abort then begin
    ;          info.abort=0
    ;          break ;skip out of case if the abort was hit waiting for the ready flag
    ;        endif
    ;        SOLOIST_FTS_status,info, 'Scan triggered.'
    ;        RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO    ;now start the scan(s). The DOUT 0 line will be set  high during scan.
    ;
    ;      endif else begin
    ;        ;start the scan immediately
    ;        RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO
    ;      endelse
    ;
    ;      ;reset the abort flag, in case the scan was aborted
    ;      info.abort=0
    ;    end
    ;    'START_SAI_SW': begin
    ;      RRCAT_SOLOIST_FTS_save_settings,info
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      info.abort=0
    ;      info.scanning=1
    ;      info.samples_acquired=0
    ;
    ;      ;set up the buffer size, in case nyquist or speed has changed
    ;      result=RRCAT_SOLOIST_FTS_INIT_ADC(info)
    ;      if result ne 1 then begin
    ;        SOLOIST_FTS_MESSAGE,info,'ADC acquisition failed: '+strtrim(result,2)
    ;        SOLOIST_FTS_MESSAGE,info,'ADC status: '+strtrim(SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj),2)
    ;        result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
    ;        info.scanning=0
    ;        return
    ;      endif
    ;
    ;      ;get the number of scans to do
    ;      info.scans_remaining = info.scans_field->get_value()
    ;      ;delete the average plots
    ;      info.ifg_plot->delete,name=['avg']
    ;      info.spc_plot->delete,name=['avg']
    ;      *info.avg_ifg=!null
    ;      *info.avg_spc=!null
    ;
    ;      if info.triggered then begin
    ;        info.dio.scanning  = 0b
    ;        bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
    ;        if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;set the ADC output line low indicating FTS is ready for trigger. This should already be low.
    ;        ready=0
    ;        SOLOIST_FTS_status,info, 'Waiting for scan trigger..'
    ;        ;wait for the ADC trigger input if in triggered scan mode
    ;        while ready eq 0 do begin
    ;          ;check if abort was hit
    ;          result=widget_event(info.abort_id,/nowait)
    ;          if result.id ne 0 then begin
    ;            info.abort=1
    ;            info.dio.scanning  = 0b
    ;            bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
    ;            if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;the FTS status is not scanning.
    ;            break ;the abort button was hit.
    ;          endif
    ;          if ~info.simADC then begin
    ;            val=SOLOIST_FTS_ADC_DIN(model=info.adc_model,obj=info.adc_obj)  ;check the input lines
    ;            ready = val AND 1b  ;ready flag is on first input
    ;          endif else begin
    ;            ;no ADC in simulate mode, so start immediately
    ;            ready = 1
    ;          endelse
    ;        endwhile
    ;
    ;        if info.abort then begin
    ;          info.abort=0
    ;          break ;skip out of case if the abort was hit waiting for the ready flag
    ;        endif
    ;        SOLOIST_FTS_status,info, 'Scan triggered.'
    ;        RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO    ;now start the scan(s). The DOUT 0 line will be set  high during scan.
    ;
    ;      endif else begin
    ;        ;start the scan immediately
    ;        RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO
    ;      endelse
    ;
    ;      ;reset the abort flag, in case the scan was aborted
    ;      info.abort=0
    ;    end
    'START_SW': begin
      RRCAT_SOLOIST_FTS_save_settings,info
      info.abort=0
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      info.scanning=1
      ;      ;
      ;      ; 16 Aug 2019
      ;      ; Disable the stepper while scanning.
      ;      ;
      ;      OBJ_destroy, info.stepper
      ;
      IF info.fts_scan_mode EQ 'Step and Integrate' THEN BEGIN
        hk = rrcat_soloist_fts_housekeeping(info, simHK=info.simHK, simADC=info.simADC)
      ENDIF ELSE BEGIN
        hk = rrcat_soloist_fts_housekeeping(info, simHK=info.simHK, simADC=info.simADC, /NO_SAI)
      ENDELSE

      info.housekeeping = hk
      ;RRCAT_SOLOIST_FTS_update_hk_status,info

      IF info.fts_scan_mode EQ 'Step and Integrate' THEN info.samples_acquired=0

      ;set up the buffer size, in case nyquist or speed has changed
      result=RRCAT_SOLOIST_FTS_INIT_ADC(info)
      if result ne 1 then begin
        SOLOIST_FTS_MESSAGE,info,'ADC acquisition failed: '+strtrim(result,2)
        SOLOIST_FTS_MESSAGE,info,'ADC status: '+strtrim(SOLOIST_FTS_ADC_status(model=info.adc_model,obj=info.adc_obj),2)
        result=SOLOIST_FTS_ADC_CLOSE(model=info.adc_model,obj=info.adc_obj)
        info.scanning=0
        return
      endif

      ;get the number of scans to do
      info.scans_remaining = info.scans_field->get_value()
      ;delete the average plots
      info.ifg_plot->delete,name=['avg']
      info.spc_plot->delete,name=['avg']
      *info.avg_ifg=!null
      *info.avg_spc=!null

      if info.triggered then begin
        info.dio.scanning  = 0b
        IF info.debug THEN BEGIN
          SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to ', STRING(bitVal)
        ENDIF
        bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
        if ~info.simADC then result=SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;set the ADC output line low indicating FTS is ready for trigger. This should already be low.
        ready=0
        SOLOIST_FTS_status,info, 'Waiting for scan trigger..'
        ;wait for the ADC trigger input if in triggered scan mode
        while ready eq 0 do begin
          ;check if abort was hit
          result=widget_event(info.abort_id,/nowait)
          if result.id ne 0 then begin
            info.abort=1
            info.dio.scanning  = 0b
            IF info.debug THEN BEGIN
              SOLOIST_FTS_MESSAGE, info, 'Setting the ADC DOUT bits to ', STRING(bitVal)
            ENDIF
            bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
            if ~info.simADC then result=RRCAT_SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)  ;the FTS status is not scanning.
            break ;the abort button was hit.
          endif
          if ~info.simADC then begin
            val=SOLOIST_FTS_ADC_DIN(model=info.adc_model,obj=info.adc_obj)  ;check the input lines
            ready = val AND 1b  ;ready flag is on first input
          endif else begin
            ;no ADC in simulate mode, so start immediately
            ready = 1
          endelse
        endwhile

        if info.abort then begin
          info.abort=0
          break ;skip out of case if the abort was hit waiting for the ready flag
        endif
        SOLOIST_FTS_status,info, 'Scan triggered.'
        ;now start the scan(s). The DOUT 0 line will be set high during scan.
        IF info.fts_scan_mode EQ 'Rapid Scan' THEN RRCAT_SOLOIST_FTS_start_scan,info,/set_PSO
        IF info.fts_scan_mode EQ 'Step and Integrate' THEN RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO
        ;RRCAT_SOLOIST_FTS_start_scan,info,/set_PSO

      endif else begin
        ;start the scan immediately
        IF info.fts_scan_mode EQ 'Rapid Scan' THEN RRCAT_SOLOIST_FTS_start_scan,info,/set_PSO
        IF info.fts_scan_mode EQ 'Step and Integrate' THEN RRCAT_SOLOIST_FTS_start_sai_scan,info,/set_PSO
        ;RRCAT_SOLOIST_FTS_start_scan,info,/set_PSO
      endelse

      ;reset the abort flag, in case the scan was aborted
      info.abort=0
    end
    'START_DELAY':begin
      b=widget_base(group_leader=event.top,/col,/modal,title='RRCAT_SOLOIST_FTS Settings')
      x=fsc_inputfield(b,/floatvalue,title='Enter delay at start of scan (s):',xsize=3,$
        decimal=1,/positive,value=info.start_delay)
      ok=widget_button(b,value='OK')
      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if (ev.id eq ok) and (bad eq 0) then begin
        val=x->get_value()
        info.start_delay = val
        widget_control,b,/dest
        SOLOIST_FTS_MESSAGE,info,'Scan start delay set to: '+string(val,format='(f0.1)')+' seconds.'
      endif
    end
    'STATUS_TIMER':begin
      soloist_fts_drive_status, info
    end
    'STEP SIZE':begin

    end
    'STEP -':begin
      if not info.simStage then begin
        if info.Soloist->In_Motion(err=err) then begin
          result=dialog_message('Stage is currently in motion!',/info, title='Error', dialog_parent=info.tlb)
        endif else begin
          current_pos=info.Soloist->Get_Pos(err=err)
          result = SOLOIST_FTS_handle_soloist_error(info, err)
          interval = info.step_field->get_value() / 1000.	;PSO interval in mm
          ;					speed = info.speed_field->get_value() * 10	;travel speed in mm/sec
          if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
          speed = info.speed_field->get_value() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.
          pos = (current_pos - interval) > (info.min_travel)
          SOLOIST_FTS_track_move,info,pos,speed=speed,err=err
        endelse
      endif else begin
        SOLOIST_FTS_message,info,'Step not available in simulate mode'
      endelse
    end
    'STEP +':begin
      if not info.simStage then begin
        if info.Soloist->In_Motion(err=err) then begin
          result=dialog_message('Stage is currently in motion!',/info, title='Error', dialog_parent=info.tlb)
        endif else begin
          current_pos=info.Soloist->Get_Pos(err=err)
          result = SOLOIST_FTS_handle_soloist_error(info, err)
          ;interval = info.sampling_field->get_value() / 1000.	;PSO interval in mm
          interval = info.step_field->get_value()/1000.	;step size in mm
          ;					speed = info.speed_field->get_value() * 10	;travel speed in mm/sec
          if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
          speed = info.speed_field->get_value() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.
          pos = (current_pos + interval) < (info.max_travel)
          SOLOIST_FTS_track_move,info,pos,speed=speed,err=err
        endelse
      endif else begin
        SOLOIST_FTS_message,info,'Step not available in simulate mode'
      endelse
    end
    'STEP_TOGGLE':begin
      if not info.simStage then begin
        if info.Soloist->In_Motion(err=err) then begin
          result=dialog_message('Stage is currently in motion!',/info, title='Error', dialog_parent=info.tlb)
        endif else begin
          WIDGET_CONTROL,info.hk_timer_base,timer=-1
          current_pos=info.Soloist->Get_Pos(err=err)
          result = SOLOIST_FTS_handle_soloist_error(info, err)
          interval = info.step_field->get_value() / 1000. ;PSO interval in mm
          ;         speed = info.speed_field->get_value() * 10  ;travel speed in mm/sec
          if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
          speed = info.speed_field->get_value() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.
          pos = (current_pos + interval) < (info.max_travel)
          info.last_move = 1
          SOLOIST_FTS_track_move,info,pos,speed=speed,err=err
          WIDGET_CONTROL,info.scan_toggle_timer_base,timer=info.scan_toggle_timer_refresh
        endelse
      endif else begin
        SOLOIST_FTS_message,info,'Step not available in simulate mode'
      endelse
    end
    'SCAN_TOGGLE_TIMER': begin
      if not info.simStage then begin
        if info.Soloist->In_Motion(err=err) then begin
          ;          if info.abort EQ 1 then begin
          ;            WIDGET_CONTROL,info.scan_toggle_timer_base,timer=info.scan_toggle_timer_refresh
          ;          endif
        endif else begin
          current_pos=info.Soloist->Get_Pos(err=err)
          result = SOLOIST_FTS_handle_soloist_error(info, err)
          interval = info.step_field->get_value() / 1000. ;PSO interval in mm
          ;         speed = info.speed_field->get_value() * 10  ;travel speed in mm/sec
          if strupcase(info.FTS_TYPE) eq 'MZ' then mult=4. else mult=2.
          speed = info.speed_field->get_value() /mult * 10  ;convert travel speed to mm/sec from cm/s OPD.
          IF info.last_move EQ 0 THEN BEGIN
            pos = (current_pos + interval) < (info.max_travel)
            info.last_move = 1
          ENDIF ELSE BEGIN
            pos = (current_pos - interval) > (info.min_travel)
            info.last_move = 0
          ENDELSE
          SOLOIST_FTS_track_move,info,pos,speed=speed,err=err
        endelse
        WIDGET_CONTROL,info.scan_toggle_timer_base,timer=info.scan_toggle_timer_refresh
      endif else begin
        SOLOIST_FTS_message,info,'Step not available in simulate mode'
      endelse
    end
    'STEPPER_ACCEL':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      accel = info.accel_field_step->get_value()
      selected_motor = info.selected_motor
      selected_motor_index = info.selected_motor_index
      stepperMotors = info.stepperMotors
      ;
      stepperMotors[selected_motor_index].accel = accel
      info.stepperMotors = stepperMotors
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'STEPPER_CONNECT': begin
      IF OBJ_VALID(info.stepper) THEN BEGIN
        OBJ_DESTROY, info.stepper
        info.simStepper = 1
        stepper_port = 'SIM'
        WIDGET_CONTROL, info.stepper_port_field, SET_VALUE=stepper_port
      ENDIF ELSE BEGIN
        stepper_port = 'COM7'
        info.stepper = rrcat_soloist_init_stepper_controller(stepperMotors=stepperMotors, port=stepper_port, baud=9600,data=8,parity='N',stop=1)
        info.simStepper = 0
        if not obj_valid(info.stepper) then begin
          result=dialog_message('Could not create BC6D20 Stepper Controller object on port '+stepper_port+'!',/err,title='Connection Error')
          info.simStepper = 1
          stepper_port = 'ERROR'
        endif else begin
          if info.debug EQ 1 then begin
            RRCAT_SOLOIST_FTS_SENSITIZE, info, /STEPPER
          endif
        endelse
        WIDGET_CONTROL, info.stepper_port_field, SET_VALUE=stepper_port
      ENDELSE
    end
    ;    'STEPPER_ASYNC':begin
    ;      ;
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      ;
    ;      ; Update the motor state fields
    ;      ;
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        data = info.stepper->getMotorState(nRetries=nRetries)
    ;        str = rrcat_stepper_parse_string(data, info, /MOTORSTATE)
    ;      ENDIF
    ;      ;
    ;      ; Get the motor
    ;      ;
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      ;
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        IF stepperMotors[selected_motor_index].state NE 0 THEN BEGIN
    ;          SOLOIST_FTS_message,info,'Unable to change motor behaviour while motor is not IDLE.'
    ;        ENDIF ELSE BEGIN
    ;          ; rrcat_soloist_get_stepper_motor_selected(info)
    ;          ;
    ;          ; Make sure the motor is not moving (i.e. IDLE)
    ;          ;
    ;          retStr = info.stepper->setAsync(motor=selected_motor_index, nRetries=nRetries)
    ;          SOLOIST_FTS_message,info,retStr
    ;          ;info.stepper_async=event.select
    ;          stepperMotors[selected_motor_index].async = event.select
    ;        ENDELSE
    ;      ENDIF
    ;      ; Check that motors are not moving
    ;      ; Set async
    ;      ;
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;    end
    'STEPPER_CURRENT':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      current = info.current_field_step->get_value()
      selected_motor = info.selected_motor
      selected_motor_index = info.selected_motor_index
      stepperMotors = info.stepperMotors
      ;
      stepperMotors[selected_motor_index].current = current
      info.stepperMotors = stepperMotors
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    ;    'STEPPER_CURRENT_IDLE':begin
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      current = info.current_idle_field_step->get_value()
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      ;
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        retStr = info.stepper->setMotorCurrentIdle(current, motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;      ENDIF
    ;      stepperMotors[selected_motor_index].currentIdle = current
    ;      info.stepperMotors = stepperMotors
    ;      ; Restart the hk updates.
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    'STEPPER_DIRECTION':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      selected_motor = info.selected_motor
      selected_motor_index = info.selected_motor_index
      stepperMotors = info.stepperMotors
      stepperMotors[selected_motor_index].direction = event.value
      ; Restart the hk updates.
      info.stepperMotors = stepperMotors
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'STEPPER_MOTOR_SELECT':begin
      info.selected_motor_index = event.index
      info.selected_motor = info.motor_list[info.selected_motor_index]
      ;STOP
      rrcat_update_stepper_motor_fields, event.index, info
      rrcat_soloist_update_stepper_status, info
    end
    'STEPPER_MOTORS':begin
    end
    ;    'STEPPER_MINUS_ENABLED':begin
    ;      ;
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      ;
    ;      ; Get the motor
    ;      ;
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      ;
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        stepperMotors[selected_motor_index].minusEnabled = event.select
    ;        retStr = info.stepper->selectMotor(motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        commandStr = rrcat_stepper_make_command_string(stepperMotors[selected_motor_index])
    ;        retStr = info.stepper->command(commandStr, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        ;
    ;      ENDIF
    ;      ; Check that motors are not moving
    ;      ; Set async
    ;      ;
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    ;    'STEPPER_PLUS_ENABLED':begin
    ;      ;
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      ;
    ;      ; Get the motor
    ;      ;
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      ;
    ;      stepperMotors[selected_motor_index].plusEnabled = event.select
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        retStr = info.stepper->selectMotor(motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        commandStr = rrcat_stepper_make_command_string(stepperMotors[selected_motor_index])
    ;        retStr = info.stepper->command(commandStr, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        ;
    ;      ENDIF
    ;      ; Check that motors are not moving
    ;      ; Set async
    ;      ;
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    ;    'STEPPER_MINUS_HARD_SOFT_LIMIT':begin
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      stepperMotors[selected_motor_index].soft_hard_limit_minus = event.value
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        retStr = info.stepper->selectMotor(motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        commandStr = rrcat_stepper_make_command_string(stepperMotors[selected_motor_index])
    ;        retStr = info.stepper->command(commandStr, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        ;
    ;      ENDIF
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    ;    'STEPPER_PLUS_HARD_SOFT_LIMIT':begin
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      stepperMotors[selected_motor_index].soft_hard_limit_plus = event.value
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        retStr = info.stepper->selectMotor(motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        commandStr = rrcat_stepper_make_command_string(stepperMotors[selected_motor_index])
    ;        retStr = info.stepper->command(commandStr, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        ;
    ;      ENDIF
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    ;    'STEPPER_MINUS_HIGH_LOW_LIMIT':begin
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      stepperMotors[selected_motor_index].high_low_limit_minus = event.value
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        retStr = info.stepper->selectMotor(motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        commandStr = rrcat_stepper_make_command_string(stepperMotors[selected_motor_index])
    ;        retStr = info.stepper->command(commandStr, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        ;
    ;      ENDIF
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    ;    'STEPPER_PLUS_HIGH_LOW_LIMIT':begin
    ;      ; Pause the hk updates.
    ;      WIDGET_CONTROL,info.hk_timer_base,timer=-1
    ;      selected_motor = info.selected_motor
    ;      selected_motor_index = info.selected_motor_index
    ;      stepperMotors = info.stepperMotors
    ;      stepperMotors[selected_motor_index].high_low_limit_plus = event.value
    ;      IF info.simStepper EQ 0 THEN BEGIN
    ;        retStr = info.stepper->selectMotor(motor=selected_motor_index, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        commandStr = rrcat_stepper_make_command_string(stepperMotors[selected_motor_index])
    ;        retStr = info.stepper->command(commandStr, nRetries=nRetries)
    ;        ;SOLOIST_FTS_message,info,retStr
    ;        ;
    ;      ENDIF
    ;      ; Restart the hk updates.
    ;      info.stepperMotors = stepperMotors
    ;      IF info.scanning EQ 0 THEN BEGIN
    ;        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
    ;      ENDIF
    ;    end
    'STEPPER_PORT':begin
      ;
      ; Read the field (make sure it begins with COM)
      stepper_port = info.stepper_port_field->get_value()
      str_pos = STRPOS(STRUPCASE(stepper_port), 'COM')
      if str_pos NE 0 THEN BEGIN
        result=dialog_message('Stepper Port must begin with COM.',$
          /error, title='Parameter Error', dialog_parent=info.tlb)
      ENDIF ELSE BEGIN
        ; Try to connect to stepper board
        info.stepper=obj_new('BC6D20',port=stepper_port,baud=9600,data=8,parity='N',stop=1)
        IF NOT OBJ_VALID(info.stepper) THEN BEGIN
          ; Send the report (if unable to connect suggest options)
          result=dialog_message('Unable to connect to stepper on port '+stepper_port+'. Check Device Manager for the correct port.',$
            /error, title='Connection Error', dialog_parent=info.tlb)
        ENDIF ELSE BEGIN
          SOLOIST_FTS_message,info,'Stepper board connected on port '+stepper_port+'.'
        ENDELSE
        ;
      ENDELSE
    end
    'STEPPER_SLEW':begin
      ; Pause the hk updates.

      IF info.scanning EQ 0 THEN BEGIN
        IF info.simStepper EQ 0 THEN BEGIN
          WIDGET_CONTROL,info.hk_timer_base,timer=-1
          WIDGET_CONTROL, info.relay_status_field, GET_VALUE = relay_status
          stat = FIX(relay_status)
          IF ((stat AND 32) EQ 0) THEN BEGIN
            result=dialog_message('You are about to slew motors when stepper relay is in the off position.',/CANCEL, title='Motor Warning')
            IF result NE 'Cancel' THEN BEGIN
              selected_motor = info.selected_motor
              selected_motor_index = info.selected_motor_index
              stepperMotors = info.stepperMotors
              direction = stepperMotors[selected_motor_index].direction
              ;
              rrcat_soloist_update_stepper_status, info
              rc = RRCAT_soloist_stepper_start_move(info, selected_motor_index, direction, debug=info.debug)
              IF rc EQ 0 THEN BEGIN
                WIDGET_CONTROL, info.motor_id, sens=0
                WIDGET_CONTROL, info.reset_id_step, sens=0
                WIDGET_CONTROL, info.slew_id_step, sens=0
                WIDGET_CONTROL,info.stepper_timer_base,timer=info.stepper_refresh
                ;
                rrcat_soloist_update_stepper_status, info
                rc = rrcat_soloist_check_stepper_move_status(info)
                IF rc EQ 1 THEN BEGIN
                  WIDGET_CONTROL,info.stepper_timer_base,timer=info.stepper_refresh
                ENDIF ELSE BEGIN
                  WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
                  WIDGET_CONTROL, info.slew_id_step, sens=1
                  WIDGET_CONTROL, info.reset_id_step, sens=1
                  WIDGET_CONTROL, info.motor_id, sens=1
                ENDELSE
              ENDIF ELSE BEGIN
                WIDGET_CONTROL, info.hk_timer_base,timer=info.hk_refresh
              ENDELSE
            ENDIF ELSE BEGIN
              WIDGET_CONTROL, info.hk_timer_base,timer=info.hk_refresh
            ENDELSE
          ENDIF ELSE BEGIN
            selected_motor = info.selected_motor
            selected_motor_index = info.selected_motor_index
            stepperMotors = info.stepperMotors
            direction = stepperMotors[selected_motor_index].direction
            ;
            rrcat_soloist_update_stepper_status, info
            rc = RRCAT_soloist_stepper_start_move(info, selected_motor_index, direction, debug=info.debug)
            IF rc EQ 0 THEN BEGIN
              WIDGET_CONTROL, info.motor_id, sens=0
              WIDGET_CONTROL, info.reset_id_step, sens=0
              WIDGET_CONTROL, info.slew_id_step, sens=0
              ;
              rrcat_soloist_update_stepper_status, info
              rc = rrcat_soloist_check_stepper_move_status(info)
              IF rc EQ 1 THEN BEGIN
                WIDGET_CONTROL, info.stepper_timer_base,timer=info.stepper_refresh
              ENDIF ELSE BEGIN
                WIDGET_CONTROL, info.stepper_timer_base,timer=-1
                WIDGET_CONTROL, info.hk_timer_base,timer=info.hk_refresh
                WIDGET_CONTROL, info.slew_id_step, sens=1
                WIDGET_CONTROL, info.reset_id_step, sens=1
                WIDGET_CONTROL, info.motor_id, sens=1
              ENDELSE
            ENDIF ELSE BEGIN
              WIDGET_CONTROL, info.hk_timer_base,timer=info.hk_refresh
            ENDELSE
          ENDELSE
        ENDIF ELSE BEGIN
          ; Simulating stepper. Restart the hk updates.
          WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
        ENDELSE
      ENDIF ELSE BEGIN
        SOLOIST_FTS_MESSAGE, info, 'Cannot slew motors when stage is scanning.'
      ENDELSE
    end
    'STEPPER_TIMER':begin
      IF info.debug THEN BEGIN
        SOLOIST_FTS_MESSAGE, info, 'Stepper Timer'
      ENDIF
      WIDGET_CONTROL,info.stepper_timer_base,timer=-1
      rrcat_soloist_update_stepper_status, info
      data = info.stepper->getStatus(nRetries=nRetries, /LATCH)
      str = rrcat_stepper_parse_string(data, info, /LATCH)
      sm = info.stepperMotors
      ;      IF info.stepperMotors[info.selected_motor_index].fault EQ 1 THEN BEGIN
      ;         m = DIALOG_MESSAGE('Motor driver ' + STRTRIM(info.selected_motor, 2) + ' is reporting a fault.',/ERROR)
      ;      ENDIF
      rc = rrcat_soloist_check_stepper_move_status(info)
      rrcat_soloist_update_stepper_status, info
      IF rc EQ 1 THEN BEGIN
        WIDGET_CONTROL,info.stepper_timer_base,timer=info.stepper_refresh
      ENDIF ELSE BEGIN
        WIDGET_CONTROL, info.hk_timer_base,timer=info.hk_refresh
        WIDGET_CONTROL, info.slew_id_step, sens=1
        WIDGET_CONTROL, info.reset_id_step, sens=1
        WIDGET_CONTROL, info.motor_id, sens=1
      ENDELSE
    end
    'STEPPER_SPEED':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      speed = info.speed_field_step->get_value()
      selected_motor = info.selected_motor
      selected_motor_index = info.selected_motor_index
      stepperMotors = info.stepperMotors
      ;
      ;SOLOIST_FTS_message,info,retStr
      stepperMotors[selected_motor_index].speed = speed
      info.stepperMotors = stepperMotors
      ; Restart the hk updates.
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'STEPPER_STATUS':begin
      ;
      ; Read the field (make sure it begins with COM)
      retStr = info.stepper->getStatus()
      SOLOIST_FTS_message,info,retStr
    end
    'STEPPER_STEPS':begin
      ; Pause the hk updates.
      WIDGET_CONTROL,info.hk_timer_base,timer=-1
      steps = info.slew_steps_field_step->get_value()
      selected_motor = info.selected_motor
      selected_motor_index = info.selected_motor_index
      stepperMotors = info.stepperMotors
      stepperMotors[selected_motor_index].steps = steps
      ; Restart the hk updates.
      info.stepperMotors = stepperMotors
      IF info.scanning EQ 0 THEN BEGIN
        WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
      ENDIF
    end
    'STEPPER_RESET':begin
      ;
      ;
      retStr = info.stepper->reset()
      IF info.debug EQ 1 THEN SOLOIST_FTS_MESSAGE, info, 'Sending software reset to stepper board. ' + retStr
      ;
    end
    'STEPPER_STOP':begin
      ;
      WIDGET_CONTROL,info.stepper_timer_base,timer=-1
      selected_motor = info.selected_motor
      selected_motor_index = info.selected_motor_index
      stepperMotors = info.stepperMotors
      retStr = info.stepper->setMotorCurrentIdle(0, motor=stepperMotors[selected_motor_index].motor)
      retStr = info.stepper->stop(motor = stepperMotors[selected_motor_index].motor)
      rrcat_soloist_update_stepper_status, info
      WIDGET_CONTROL, info.slew_id_step, sens=1
      WIDGET_CONTROL, info.reset_id_step, sens=1
      WIDGET_CONTROL, info.motor_id, sens=1
      WIDGET_CONTROL, info.hk_timer_base,timer=info.hk_refresh
      ;SOLOIST_FTS_message,info,retStr
    end
    'SYMMETRICAL':begin
      info.ds_field->setProperty,sensitive=~event.select
      info.symmetrical=event.select
      check_resolution,info
    end
    'TIMER':begin
      RRCAT_SOLOIST_FTS_process_timer,info
    end
    'TRIGGER':begin	;set or reset the triggered scan mode
      info.triggered = event.select
    end
    ;    'WN':begin  ;set freq units to wn
    ;      if info.freq_units eq 'ghz' then begin ;previous units were wavenumber, rescale the plot
    ;        info.spc_plot->SetAxisProperty,xtitle='Wavenumber (cm!E-1!N)'
    ;        if info.spc_plot->isContained('current') then begin
    ;          prev=info.spc_plot->getData('current')
    ;          ghz=ghz2wn(prev[0,*])
    ;          info.spc_plot->setData,'current',ghz,prev[1,*]
    ;        endif
    ;        if info.spc_plot->isContained('avg') then begin
    ;          prev=info.spc_plot->getData('avg')
    ;          ghz=ghz2wn(prev[0,*])
    ;          info.spc_plot->setData,'avg',ghz,prev[1,*]
    ;        endif
    ;        if info.spc_plot->isContained('file') then begin
    ;          prev=info.spc_plot->getData('file')
    ;          ghz=ghz2wn(prev[0,*])
    ;          info.spc_plot->setData,'file',ghz,prev[1,*]
    ;        endif
    ;        info.spc_plot->getAxisProperty,xrange=xrange
    ;        info.spc_plot->setAxisProperty,xrange=ghz2wn(xrange)
    ;        info.spc_plot->show
    ;
    ;        ;get currently selected nyquist list index
    ;        text=widget_info(info.nyquist_id,/combobox_gettext)
    ;        result=min(abs(ghz2wn(float(text))-(*info.nyquist_list)),ind)
    ;
    ;        ;set up Nyquist list in cm-1 units
    ;        nyquist_list=*info.nyquist_list
    ;        widget_control,info.nyquist_id,set_value=string(nyquist_list,format='(f7.2)'), set_combobox_select=ind
    ;
    ;        id=widget_info(info.tlb,find_by_uname='nyquist list label')
    ;        widget_control,id,set_value='Nyquist (cm-1)'
    ;        info.max_freq_field->setProperty,title='Max. Signal Freq. (cm-1)'
    ;        info.max_freq_field->set_value,info.max_freq
    ;        resolution=info.resolution_field->get_value()
    ;        info.resolution_field->set_value, ghz2wn(resolution)
    ;        info.resolution_field->setProperty,title='Resolution (cm-1)'
    ;      endif
    ;      info.freq_units='wn'
    ;      widget_control,event.id,set_value='GHz Units',set_uvalue='GHZ'
    ;    end
    'ZPD':begin
      b=widget_base(group_leader=event.top,/col,/modal,/base_align_center,title='RRCAT_SOLOIST_FTS Settings')
      b2=widget_base(b,/col,/frame,/base_align_center)
      zpd=fsc_inputfield(b2,/floatvalue,title='Enter apparent ZPD position (cm OPD):',xsize=8,decimal=4,value=0.)
      id=widget_base(b2)
      ok=widget_button(id,value='Accept',uvalue='accept_OPD')
      b3=widget_base(b,/col,/frame,/base_align_center)
      mpd=fsc_inputfield(b3,/floatvalue,title='Enter ZPD position in mm MPD:',xsize=9,decimal=3,value=info.zpd)
      id=widget_base(b3)
      reset=widget_button(id,value='Reset ZPD to top of stage',uval='reset MPD')
      id=widget_base(b3)
      ok=widget_button(id,value='Accept',uvalue='accept_MPD')

      widget_control,b,/real
      ev=widget_event(b,bad_id=bad)
      if bad eq 0 then begin
        widget_control,ev.id,get_uvalue=uval
        case uval of
          'accept_OPD' : begin
            apparent_zpd=zpd->get_value()
            old_zpd=info.zpd ;ZPD is in mm MPD
            if info.FTS_Type eq 'MZ' then mult=4. else mult=2.
            new_zpd = apparent_zpd * 10./ mult + old_zpd		;since OPD(cm) = (MPD(mm) - ZPD(mm)) / 10. *2  for Michelson, or
            info.zpd = (info.min_travel)>new_zpd<(info.max_travel)				;OPD(cm) = (MPD(mm) - ZPD(mm)) / 10. *4 for MZ
            info.ifg_plot->SetAxisProperty,xrange=SOLOIST_FTS_pos_to_opd(info,[info.min_travel,info.max_travel])
            info.ifg_plot->show
            widget_control,b,/dest
          end
          'accept_MPD' : begin
            zpd=mpd->get_value()
            zpd=(info.min_travel)>zpd<(info.max_travel)	;ZPD is in mm MPD
            info.zpd = zpd
            info.ifg_plot->SetAxisProperty,xrange=SOLOIST_FTS_pos_to_opd(info,[info.min_travel,info.max_travel])
            info.ifg_plot->show
            widget_control,b,/dest
          end
          'reset MPD' :begin
            info.zpd = (info.min_travel)>0.<(info.max_travel)
            info.ifg_plot->SetAxisProperty,xrange=SOLOIST_FTS_pos_to_opd(info,[info.min_travel,info.max_travel])
            info.ifg_plot->show
            widget_control,b,/dest
          end
          else :
        endcase
        check_resolution,info
      endif
      IF info.fts_selected EQ 'Martin-Puplett' then info.zpd_lw = info.zpd
      IF info.fts_selected EQ 'Michelson' then info.zpd_sw = info.zpd
    end
    else:message,'unhandled event in top level base: '+thisEvent,/info

  ENDCASE

  RRCAT_SOLOIST_FTS_SAVE_SETTINGS,info		;save the settings in case the widget is killed.

  Widget_Control, event.top, Set_UValue=info;, /No_Copy

END ;----------------------------------------------------------------------------

