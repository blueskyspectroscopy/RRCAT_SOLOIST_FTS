;+
; NAME:
;	RRCAT_SOLOIST_FTS
;
; PURPOSE:
;	This is the control interface for the SOLOIST FTS. This program controls the
;	stage motion and data acquisition system to record interferograms. See the
;	help file for more information.
;
;	Be sure that the ethernet timeout parameter is set to a very large value in the
;	Soloist parameters!
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	DEBUG:	Set this keyword to generate debugging messages.
;	SIMSTAGE:	Set this keyword to simulate all Soloist communication
;	SIMADC:	Set this keyword to simulate all ADC communication
; SIMSTEPPER: Set this keyword to simulate communication with the stepper controller
; SIMCHOPPER: Set this keyword to simulate communication with the chopper
; SIMLIA: Set this to simulate communication with the LIA
; SIMRELAY: Set this to simulate communication with the relay controller
;
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
;	Apr 10 2008 - added triggered input mode. Version 1.4
;			In this mode, the selected number of scans start when a high value is read on DIN 0 after the start button is pressed.
;			DOUT 0 = low when FTS is not in triggered mode, or when FTS is in triggered mode but not scanning.
;			DOUT 0 = high when the software is in triggered mode and a scan has been started
;	Jun 30 2009 - added menu options for network settings
;					- added menu options for stage travel
;					- added flag for interferometer type. This should eventually be a menu option.
;  Jul 6 2009 - added GUI options for changing FTS type, resetting soloist and ADC, etc.
;  Oct 15 2009 - fixed soloist bug resulting in incorrect sampling at high nyquist.
;  Nov 16 2009 - fixed bug in soloist_fts when simadc flag is set.
;  				- fixed bug in apparent ZPD field
;  Nov 25 2009 - added option to use internal ADC clock instead of TTL trigger
;  Jan 12 2010 - added otion to save\load settings files
;  Mar 17 2012 - several bug fixes.
;              - ensure 'always send EOS' is configured in soloist
;              - added SET_WAIT_MODE method to soloistobj, to prevent blocking during commands
;              - added autoscaling for IFG axis
;              - added GHz spectral scale
;              - buffer length now calculated based on time
;  Apr 8 2014 - modified to use PSO window
;             - added menu options for home speed and acceleration.
;
;  May 25 2015 - changed buffer behaviour. Buffer length is now specified in samples, not in seconds.
;
;     -** The ADC DLM only seems to behave properly when the acquisition length is an integer number of buffer lengths,
;     and the buffer length needs to be a multiple of 32.
;
;  Aug 11 2015 - added checks in the event handler to prevent scan speed being too high for given buffer length.
;                 Assuming 0.1 seconds per buffer is possible without crashing.
;
;  Nov 18 2016 - changed to store ifg and spc pointers instead of using plot objects to store the data
;              - now averages complex spectra instead of power spectrum, equivalent to averaging the interferogram.
;
;  Aug 17 2017 - changed PSO window behaviour. Differences between MP and CP soloists
;              - support for DT7816
;              - support for MC1808X
;              - added Hz frequency option for audio frequency display
;              - changed settings file format with new fields for ADC etc.
;
;  Nov 7 2017  - added a RENDERER keyword to SOLOIST_FTS and SOLOIST_FTS_RENDERER system variable. Some systems might not display the axis text properly
;               in either the hardware or software renderer. Some systems might have slow plot performance in the hardware
;               renderer while zooming. To fix this, try setting the renderer to 1 (software) or 0 (hardware OpenGL).
;
;  Dec 11 2017 - (TRF) Modified for RRCAT. This includes adding GUI elements to switch between each FTS/optics/detector.
;  17 May 2018 - (TRF) Added LIA tab.
;  03 Jul 2019 - (TRF) Initialize the KTA relay first. Check its setting and ensure that 
;                      Stage (1), Metrology (4) and Steppers (32) are enabled.
;                      
;  04 Jul 2019 - (TRF) Revert back to steppers init before fuse init
;  12 Jul 2019 - (TRF) Removed Step and Integrate specific widget items.
;  30 Jul 2019 - (TRF) Added det_temp to hk structure
;  01 Aug 2019 - (TRF) Added profiler
;  30 Aug 2019 - (TRF) Stepper timer refresh set to 0.1 s
;  19 Sep 2019 - (TRF) FTS Selection mirror is index 3 (M4)
;  
;TODO: -look into why changing home speed causes PSO to cut out on subsequent scans (ML)
;
;TODO: -add GUI field for MC1808 serial number
;TODO: -don't use buffer length in travel calculation for MC1808X. Use 128 points instead. Currently code makes travel an integer number of buffer lengths
;TODO: -use zeropadded interferogram, with efficient total length. Plot refresh can take a long time at some intermediate ifg lengths
;TODO: -display error message when stage is in limit at startup
;TODO: -add position marker to BGPlotWidget.
;
;TODO: -pass debug keyword to ADC calls for logging
;TODO: -check debugging log where FTS type appears incorrect after ADC fail.
;TODO: -Improve debugging messages for ADC software install issues
;TODO: -debug messages for Soloist errors.

;TODO: -change all mechanical position values to mm instead of cm.
;TODO: -make resize events change the status field height.
;
;TODO: -custom delays for reset etc depending on system
;TODO: -are triggered scans possible on DT7816?
;TODO: -add maximum stage speed to parameter file (used in check_speed in rrcat_soloist_fts_Event)
;TODO: -add maximum ADC buffers/sec to parameter file (used in check_speed in rrcat_soloist_fts_Event, except for MC1808X)
;TODO: -allow saving/displaying multiple channels. This is supported in DT7816 and MC1808X
;-

pro RRCAT_SOLOIST_FTS,debug=debug_, simStage=simStage_, simADC=simADC_, simStepper=simStepper_, $
  simChopper=simChopper_, simLia=simLia_, simRelay=simRelay_, simHK=simHK_, renderer=renderer_
  
  PROFILER, /RESET
  PROFILER, /SYSTEM
  PROFILER
  
  working_dir = 'c:\rrcat_soloist_fts\'
  if not (file_test(working_dir,/dir)) then file_mkdir, working_dir 	;make sure data directory exists c:\rrcat_soloist_fts
  title='RRCAT Soloist FTS Control'

  debug=1
  simADC=0
  simStage=0
  simStepper=0
  simChopper=0
  simLia=0
  simRelay=0
  simHk=0
  renderer=0

  if getenv('SOLOIST_FTS_DEBUG') eq '1' then debug=1
  if getenv('SOLOIST_FTS_SIM_ADC') eq '1' then simADC=1
  if getenv('SOLOIST_FTS_SIM_STAGE') eq '1' then simStage=1
  if getenv('SOLOIST_FTS_SIM_STEPPER') eq '1' then simStepper=1
  if getenv('SOLOIST_FTS_SIM_CHOPPER') eq '1' then simChopper=1
  if getenv('SOLOIST_FTS_SIM_LIA') eq '1' then simLia=1
  if getenv('SOLOIST_FTS_SIM_RELAY') eq '1' then simRelay=1
  if getenv('SOLOIST_FTS_SIM_HK') eq '1' then simHk=1
  if getenv('SOLOIST_FTS_RENDERER') eq '1' then renderer=1

  ;the keyword parameters override the environment variables.
  if n_elements(debug_) ne 0 then debug=debug_
  if debug ne 0 then debug=1
  if n_elements(simStage_) ne 0 then simStage=simStage_
  if simStage ne 0 then simStage=1
  if n_elements(simADC_) ne 0 then simADC=simADC_
  if simADC ne 0 then simADC=1
  if n_elements(simStepper_) ne 0 then simStepper=simStepper_
  if simStepper ne 0 then simStepper=1
  if n_elements(simChopper_) ne 0 then simChopper=simChopper_
  if simChopper ne 0 then simChopper=1
  if n_elements(simLia_) ne 0 then simLia=simLia_
  if simLia ne 0 then simLia=1
  if n_elements(simRelay_) ne 0 then simRelay=simRelay_
  if simRelay ne 0 then simRelay=1
  if n_elements(simHK_) ne 0 then simHK=simHK_
  if simHK ne 0 then simHK=1
  if n_elements(renderer_) ne 0 then renderer=renderer_
  if renderer ne 0 then renderer=1

  if debug then title=title+' [Debug Mode]'
  if simStage then title=title+' [Simulating Stage]'
  if simADC then title=title+' [Simulating ADC]'
  if simStepper then title=title+' [Simulating Stepper]'
  if simChopper then title=title+' [Simulating Chopper]'
  if simLia then title=title+' [Simulating LIA]'
  if simRelay then title=title+' [Simulating Relay]'
  if simHK then title = title+' [Simulating Housekeeping]'

  if debug then begin ;write log file in debug mode
    if !journal ne 0 then journal ;if a log file is open, close it.
    caldat,systime(/jul),mo,d,y,h,m,s
    journal,working_dir+'rrcat_soloist_fts_log_'+string(y,mo,d,h,m,s,format='(I4,I2.2,I2.2,"_",I2.2,I2.2,I2.2)')+'.txt'

    printf,!journal,'Searching for ADC DLMs:'
    help,/dlm,names=['DT98*_DLM'],output=output
    if output[0] eq '' then output='No DT9800 DLMs registered!'
    printf,!journal,output
    help,/dlm,names=['MC1808X_DLM'],output=output
    if output[0] eq '' then output='No MC1808X DLM registered!'
    printf,!journal,output
  endif

  plot_xsize=800
  plot_ysize=340  ;this should be larger than the tab widget height during initialization.

  tlb=widget_base(/col,title=title,/tlb_size_events, mbar=bar, $
    notify_realize='RRCAT_SOLOIST_FTS_REALIZE', kill_notify='RRCAT_SOLOIST_FTS_KILL')
  ;notify_realize='SOLOIST_FTS_REALIZE', kill_notify='SOLOIST_FTS_KILL')

  file_menu = WIDGET_BUTTON(bar, VALUE='File', /MENU)
  x=WIDGET_BUTTON(file_menu, VALUE='Open File', UVALUE='OPEN')
  x=WIDGET_BUTTON(file_menu, VALUE='')
  x=WIDGET_BUTTON(file_menu, VALUE='Save Current SPC', UVALUE='SAVE_CURRENT')
  x=WIDGET_BUTTON(file_menu, VALUE='Save Average SPC', UVALUE='SAVE_AVG')
  x=WIDGET_BUTTON(file_menu, VALUE='')
  x=WIDGET_BUTTON(file_menu, VALUE='Save Settings', UVALUE='SAVE_SETTINGS')
  x=WIDGET_BUTTON(file_menu, VALUE='Load Settings', UVALUE='LOAD_SETTINGS')
  x=WIDGET_BUTTON(file_menu, VALUE='')
  x=WIDGET_BUTTON(file_menu, VALUE='Convert to ASCII', UVALUE='ASCII')
  x=WIDGET_BUTTON(file_menu, VALUE='')
  x=WIDGET_BUTTON(file_menu, VALUE='Print', UVALUE='PRINT')
  x=WIDGET_BUTTON(file_menu, VALUE='')
  x=WIDGET_BUTTON(file_menu, VALUE='Quit', UVALUE='QUIT')

  option_menu = WIDGET_BUTTON(bar, VALUE='Options', /MENU)
  x=WIDGET_BUTTON(option_menu, VALUE='System', /MENU)
  y=WIDGET_BUTTON(x, VALUE='Set Data Directory', UVALUE='DIRECTORY')
  y=WIDGET_BUTTON(x, VALUE='Network Setup', UVALUE='ADDRESS')
  y=WIDGET_BUTTON(x, VALUE='FTS Type', UVALUE='FTS_SELECT')
  y=WIDGET_BUTTON(x, VALUE='Mode Type', UVALUE='OPTICS_TYPE')
  y=WIDGET_BUTTON(x, VALUE='Detector Type', UVALUE='DETECTOR_TYPE')
  y=WIDGET_BUTTON(x, VALUE='Status update rate', UVALUE='HK_REFRESH')

  x=WIDGET_BUTTON(option_menu, VALUE='ADC', /MENU)
  y=WIDGET_BUTTON(x, VALUE='ADC Model', UVALUE='ADC_MODEL')
  y=WIDGET_BUTTON(x, VALUE='Buffer Size', UVALUE='BUFFER')
  ;y=WIDGET_BUTTON(x, VALUE='Step and Integrate Samples', UVALUE='DET_SAMPLES')
  y=WIDGET_BUTTON(x, VALUE='ADC Range', UVALUE='ADC_RANGE')
  y=WIDGET_BUTTON(x, VALUE='Trigger', UVALUE='ADC_TRIGGER')

  x=WIDGET_BUTTON(option_menu, VALUE='Stage', /MENU)
  y=WIDGET_BUTTON(x, VALUE='Set Scanning Mode', UVALUE='FTS_SCAN_MODE')
  y=WIDGET_BUTTON(x, VALUE='Set Max Travel', UVALUE='MAX_TRAVEL')
  y=WIDGET_BUTTON(x, VALUE='Set Min Travel', UVALUE='MIN_TRAVEL')
  y=WIDGET_BUTTON(x, VALUE='Set Encoder Channel', UVALUE='ENCODER')
  y=WIDGET_BUTTON(x, VALUE='Set ZPD Location', UVALUE='ZPD')
  y=WIDGET_BUTTON(x, VALUE='Set Acceleration', UVALUE='ACCELERATION')
  y=WIDGET_BUTTON(x, VALUE='Set Home Speed', UVALUE='HOME_SPEED')
  y=WIDGET_BUTTON(x, VALUE='Set Start Delay', UVALUE='START_DELAY')
  y=WIDGET_BUTTON(x, VALUE='Set Metrology', UVALUE='FTS_METROLOGY')

  x=WIDGET_BUTTON(option_menu, VALUE='Detector', /MENU)
  y=WIDGET_BUTTON(x, VALUE='Set Detector Freq Response', UVALUE='FREQ')

  x=WIDGET_BUTTON(option_menu, VALUE='')
  x=WIDGET_BUTTON(option_menu, VALUE='Reset ADC', UVALUE='RESET ADC')
  x=WIDGET_BUTTON(option_menu, VALUE='Reset Soloist', UVALUE='RESET SOLOIST')
  x=WIDGET_BUTTON(option_menu, VALUE='')
  x=WIDGET_BUTTON(option_menu, VALUE='Connect Stepper', UVALUE='STEPPER_CONNECT')
  x=WIDGET_BUTTON(option_menu, VALUE='Connect Chopper', UVALUE='CHOPPER_CONNECT')
  x=WIDGET_BUTTON(option_menu, VALUE='Connect LIA', UVALUE='LIA_CONNECT')
  x=WIDGET_BUTTON(option_menu, VALUE='Connect Relay', UVALUE='RELAY_CONNECT')
  x=WIDGET_BUTTON(option_menu, VALUE='', UVALUE='')
  if debug then value='Disable Log' else value='Enable Log'
  x=WIDGET_BUTTON(option_menu, VALUE=value, UVALUE='LOG')

  plot_menu = WIDGET_BUTTON(bar, VALUE='Plot', /MENU)
  x=WIDGET_BUTTON(plot_menu, VALUE='Reset Ranges', UVALUE='RANGE')
  x=WIDGET_BUTTON(plot_menu, VALUE='Hide Current', UVALUE='HIDE_CURRENT', uname='hide current')
  x=WIDGET_BUTTON(plot_menu, VALUE='Hide Average', UVALUE='HIDE_AVERAGE', uname='hide average')
  x=WIDGET_BUTTON(plot_menu, VALUE='Clear File', UVALUE='CLEAR_FILE')
  x=WIDGET_BUTTON(plot_menu, VALUE='')
  x=WIDGET_BUTTON(plot_menu, VALUE='Lock IFG X Axis', UVALUE='LOCK_IFG_X', uname='autoscale ifg x')
  x=WIDGET_BUTTON(plot_menu, VALUE='Autoscale IFG Y Axis', UVALUE='AUTO_IFG_Y', uname='autoscale ifg y')
  x=WIDGET_BUTTON(plot_menu, VALUE='')
  x=WIDGET_BUTTON(plot_menu, VALUE='Log Spectral Intensity', UVALUE='LOG_SPC', uname='spc yscale')
  x=WIDGET_BUTTON(plot_menu, VALUE='Lock SPC Y Axis', UVALUE='LOCK_SPC_Y', uname='autoscale spc')
  x=WIDGET_BUTTON(plot_menu, VALUE='Frequency Units', UVALUE='FREQ_UNITS', uname='freq units')
  x=WIDGET_BUTTON(plot_menu, VALUE='')
  x=WIDGET_BUTTON(plot_menu, VALUE='IFG Mouse Mode', UVALUE='IFG_MOUSE')
  x=WIDGET_BUTTON(plot_menu, VALUE='SPC Mouse Mode', UVALUE='SPC_MOUSE')

  help_menu = WIDGET_BUTTON(bar, VALUE='Help', /MENU)
  x=WIDGET_BUTTON(help_menu, VALUE='Contents', UVALUE='HELP')
  x=WIDGET_BUTTON(help_menu, VALUE='')
  x=WIDGET_BUTTON(help_menu, VALUE='About',UVALUE='ABOUT')

  base=widget_base(tlb,/row,tab_mode=1)
  fts_base = widget_tab(base,uvalue='FTS_TAB_SELECT')
  sw_control_base=widget_base(fts_base,/col,/base_align_center, title='FTS',event_pro='rrcat_soloist_fts_Event',uvalue='FTS')
  ;lw_control_base=widget_base(fts_base,/col,/base_align_center, title='MP',event_pro='rrcat_soloist_fts_Event',uvalue='MARTIN-PUPLETT')
  soloist_control_base=widget_base(fts_base,/col,/base_align_center, title='SOLOIST',event_pro='rrcat_soloist_fts_Event',uvalue='SOLOIST')
  stepper_control_base=widget_base(fts_base,/col,/base_align_center, title='Stepper Motors',event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_MOTORS')
  ;  stepper_limit_control_base=widget_base(fts_base,/col,/base_align_center, title='Stepper Limits',event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_LIMITS')
  chopper_control_base=widget_base(fts_base,/col,/base_align_center, title='Chopper',event_pro='rrcat_soloist_fts_Event',uvalue='CHOPPER_CONTROL')
  lia_control_base=widget_base(fts_base,/col,/base_align_center, title='LIA',event_pro='rrcat_soloist_fts_Event',uvalue='LIA_CONTROL')
  relay_control_base=widget_base(fts_base,/col,/base_align_center, title='Relays',event_pro='rrcat_soloist_fts_Event',uvalue='RELAY_CONTROL')
  ;base=widget_base(tlb,/row,tab_mode=1)
  timer_base=widget_base(base,uvalue='TIMER')	;timer for plot updates
  sai_timer_base=widget_base(base,uvalue='SAI_TIMER') ;timer for plot updates during sai scans
  status_timer_base=widget_base(base,uvalue='STATUS_TIMER')	;timer for status updates
  hk_timer_base=widget_base(base,uvalue='HK_TIMER') ;timer for housekeeping updates
  stepper_timer_base=widget_base(base,uvalue='STEPPER_TIMER') ;timer for housekeeping updates
  scan_toggle_timer_base=widget_base(base,uvalue='SCAN_TOGGLE_TIMER') ;timer for housekeeping updates

  tab_base_sw=widget_tab(sw_control_base, uvalue='NULL')
  ;tab for the FTS control inputs
  control_base_sw=widget_base(tab_base_sw,/col,/base_align_center, title='Setup')

  x=widget_label(control_base_sw,/align_center,value='Scan Parameters')
  parm_base_sw=widget_base(control_base_sw,/col,/base_align_right,/frame)
  speed_field_sw=fsc_inputfield(parm_base_sw,/float,title='Speed (cm/s)',/cr_only,xsize=5,decimal=3,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='SPEED')
  resolution_field_sw=fsc_inputfield(parm_base_sw,/float,title='Resolution (cm-1)',/cr_only,xsize=8,decimal=3,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='RESOLUTION')

  ;the nyquist values all get updated in the soloist_fts_load_settings routine.
  nyq_base_sw=widget_base(parm_base_sw,/row)
  sampling=reverse((findgen(1000)+1)/1000)	;valid PSO intervals in mm. Minimum interval is 1um
  ;*********
  ;sampling=[sampling,0.0015,0.0025,0.0035]
  ;sampling=reverse(sampling[sort(sampling)])
  ;*********

  ;start with Michelson nyquist values. This will be updated in the soloist_fts_realize routine. *** IS this the case?
  nyquist=1./(4.*sampling/10.)	;for Michelson FTS
  ;							inds=where((nyquist le 1000.) and (nyquist ge 10))	;useful Nyquist values
  inds=where(nyquist ge 20)	;useful Nyquist values
  sampling_list=sampling[inds]
  nyquist_list=nyquist[inds]
  sampling_list_laser=[1.54998/2.]/1000.
  nyquist_list_laser = 1./(4.*sampling_list_laser/10.)
  ;*********
  ;print,sampling_list
  ;print,nyquist_list
  ;*********
  id = widget_label(nyq_base_sw,value='Nyquist (cm-1)',uname='nyquist list label')
  nyquist_id_sw = widget_combobox(nyq_base_sw, value=string(nyquist_list,format='(f8.2)'),uvalue='NYQUIST')

  max_freq_field_sw=fsc_inputfield(parm_base_sw,/float,title='Max. Signal Freq. (cm-1)',/cr_only,xsize=7,decimal=2,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='MAX_FREQ')

  sym_button_sw=cw_bgroup(parm_base_sw, 'Symmetrical Scans', /return_name, /nonexclusive, uvalue='SYMMETRICAL')
  ds_field_sw=fsc_inputfield(parm_base_sw,/float,title='Double Sidedness (cm OPD)',/cr_only,xsize=5,decimal=3,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='DOUBLE_SIDED')


  x=widget_label(control_base_sw,/align_center,value='Scan Control')
  scan_base_sw=widget_base(control_base_sw,/col,/frame)
  trig_base_sw=widget_base(scan_base_sw,/row)
  trigger_checkbox_sw=cw_bgroup(trig_base_sw,'Triggered Scans',/nonexclusive,uvalue='TRIGGER')
  scan_base2_sw=widget_base(scan_base_sw,/row)
  scans_field_sw=fsc_inputfield(scan_base2_sw,/long,title='# of Scans',$
    /focus,/cr_only,xsize=4,event_pro='rrcat_soloist_fts_Event',uvalue='SCANS')
  start_id_sw=widget_button(scan_base_sw,value='Start',uvalue='START_SW')
  ;start_sai_id_sw=widget_button(scan_base_sw,value='Step and Integrate',uvalue='START_SAI_SW')
  abort_id_sw=widget_button(scan_base_sw,value='Abort',uvalue='ABORT')

  scan_mode_base=widget_base(control_base_sw,/row,/frame,tab_mode=0)
  x=widget_label(scan_mode_base,/align_left,value='Scan Mode')
  x=widget_text(scan_mode_base,xsize=30,uname='scan_mode',tab_mode=0,edit=0)

  x=widget_label(control_base_sw,/align_center,value='Step and Integrate')
  sai_base = widget_base(control_base_sw,/col, /frame)
  sai_wait_field=fsc_inputfield(sai_base,/float,title='Delay (s)',/cr_only,xsize=5,decimal=3,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='SAI_WAIT', value = 0.5)
;  sai_samp_field=fsc_inputfield(sai_base,/float,title='Samples/step',/cr_only,xsize=5,decimal=3,$
;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='SAI_SAMPLES_PER_STEP')
;  sai_freq_field=fsc_inputfield(sai_base,/float,title='Frequency (Hz)',/cr_only,xsize=5,decimal=3,$
;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='SAI_SAMPLING_FREQ')

  ;-------------------------------------------------------------------
  ;  tab_base_lw=widget_tab(lw_control_base, uvalue='NULL')
  ;  ;tab for the FTS control inputs
  ;  control_base_lw=widget_base(tab_base_lw,/col,/base_align_center, title='Setup')
  ;
  ;  x=widget_label(control_base_lw,/align_center,value='Scan Parameters')
  ;  parm_base_lw=widget_base(control_base_lw,/col,/base_align_right,/frame)
  ;  speed_field_lw=fsc_inputfield(parm_base_lw,/float,title='Speed (cm/s)',/cr_only,xsize=5,decimal=3,$
  ;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='SPEED')
  ;  resolution_field_lw=fsc_inputfield(parm_base_lw,/float,title='Resolution (cm-1)',/cr_only,xsize=8,decimal=3,$
  ;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='RESOLUTION')
  ;
  ;  ;the nyquist values all get updated in the soloist_fts_load_settings routine.
  ;  nyq_base_lw=widget_base(parm_base_lw,/row)
  ;  sampling=reverse((findgen(1000)+1)/1000)  ;valid PSO intervals in mm. Minimum interval is 1um
  ;  ;*********
  ;  ;sampling=[sampling,0.0015,0.0025,0.0035]
  ;  ;sampling=reverse(sampling[sort(sampling)])
  ;  ;*********
  ;
  ;  ;start with Michelson nyquist values. This will be updated in the soloist_fts_realize routine. *** IS this the case?
  ;  nyquist=1./(4.*sampling/10.)  ;for Michelson FTS
  ;  ;             inds=where((nyquist le 1000.) and (nyquist ge 10))  ;useful Nyquist values
  ;  inds=where(nyquist ge 20) ;useful Nyquist values
  ;  sampling_list=sampling[inds]
  ;  nyquist_list=nyquist[inds]
  ;  ;*********
  ;  ;print,sampling_list
  ;  ;print,nyquist_list
  ;  ;*********
  ;  id = widget_label(nyq_base_lw,value='Nyquist (cm-1)',uname='nyquist list label')
  ;  nyquist_id_lw = widget_combobox(nyq_base_lw, value=string(nyquist_list,format='(f8.2)'),uvalue='NYQUIST')
  ;
  ;  max_freq_field_lw=fsc_inputfield(parm_base_lw,/float,title='Max. Signal Freq. (cm-1)',/cr_only,xsize=7,decimal=2,$
  ;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='MAX_FREQ')
  ;
  ;  sym_button_lw=cw_bgroup(parm_base_lw, 'Symmetrical Scans', /return_name, /nonexclusive, uvalue='SYMMETRICAL')
  ;  ds_field_lw=fsc_inputfield(parm_base_lw,/float,title='Double Sidedness (cm OPD)',/cr_only,xsize=5,decimal=3,$
  ;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='DOUBLE_SIDED')
  ;
  ;  x=widget_label(control_base_lw,/align_center,value='Scan Control')
  ;  scan_base_lw=widget_base(control_base_lw,/col,/frame)
  ;  trig_base_lw=widget_base(scan_base_lw,/row)
  ;  trigger_checkbox_lw=cw_bgroup(trig_base_lw,'Triggered Scans',/nonexclusive,uvalue='TRIGGER')
  ;  scan_base2_lw=widget_base(scan_base_lw,/row)
  ;  scans_field_lw=fsc_inputfield(scan_base2_lw,/long,title='# of Scans',$
  ;    /focus,/cr_only,xsize=4,event_pro='rrcat_soloist_fts_Event',uvalue='SCANS')
  ;  start_id_lw=widget_button(scan_base_lw,value='Start',uvalue='START_LW')
  ;  ;start_sai_id_lw=widget_button(scan_base_lw,value='Step and Integrate',uvalue='START_SAI_LW')
  ;  abort_id_lw=widget_button(scan_base_lw,value='Abort',uvalue='ABORT')

  ;  ;tab for the Soloist status information
  ;  soloist_base_lw=widget_base(tab_base_lw,/col,/base_align_center,title='Soloist Status')
  ;  status=['Pos. Command','Pos. Feedback','External Pos.',$
  ;    'Analog In 0','Analog In 1','Analog Out 0','Analog Out 1',$
  ;    'Digital In','Digital Out']
  ;
  ;  val={poscmd:0d, pfbk:0d, extpos:0d, ain0:0., ain1:0., aout0:0., aout1:0., din:0ul, dout:0ul} ;just a placeholder for now. Update in soloist_fts_drive_status
  ;
  ;  drive_status_id_lw=widget_table(soloist_base_lw,row_labels=status,/no_column_headers,/column_major,frame=1,$
  ;    xsize=1,ysize=n_elements(status),editable=0,column_widths=[100],scroll=0,sens=0,value=val)
  ;
  ;  widget_control,drive_status_id_lw,set_table_select=[-1,-1,-1,-1]
  ;
  ;  stage_base_lw=0l
  ;  step_field_lw=obj_new()
  ;  if debug then begin ;only display stage controls in debug mode
  ;    x=widget_label(soloist_base_lw,/align_center,value='Stage Control')
  ;    stage_base_lw=widget_base(soloist_base_lw,/col,/base_align_center,frame=1)
  ;    x=widget_button(stage_base_lw,value='Home',uvalue='HOME')
  ;    step_field_lw=fsc_inputfield(stage_base_lw,/long,value=1,title='Stage step size (um)',/cr_only,xsize=5,event_pro='rrcat_soloist_fts_Event',uvalue='STEP SIZE')
  ;    base2=widget_base(stage_base_lw,/row)
  ;    x=widget_button(base2,value='Step -',uvalue='STEP LW -')
  ;    x=widget_button(base2,value='Step +',uvalue='STEP LW +')
  ;  endif
  ;
  ;
  ;  ;tab for the Soloist fault information
  ;  soloist_fault_base_lw=widget_base(tab_base_lw,/col,/base_align_center,title='Soloist Faults')
  ;  ack_id_lw=widget_button(soloist_fault_base_lw,value='Acknowledge Fault',uvalue='ACK',/align_center)
  ;  faults=['Position Error','Over Current Fault','CW Hardware Limit','CCW Hardware Limit',$
  ;    'CW Software Limit','CCW Software Limit','Drive Fault',$
  ;    'Position Feedback Fault','Velocity Feedback Fault','Hall Effect Input Fault',$
  ;    'Max Vel Command Fault','ESTOP Fault','Velocity Error Fault','Task Fault',$
  ;    'Probe Fault','Aux Fault','Safe Zone Fault','Motor Temp. Fault','Amplifer Temp. Fault']
  ;
  ;  Fault_id_lw=widget_table(soloist_fault_base_lw,row_labels=faults,/no_column_headers,frame=1,$
  ;    background_color=[0,255,0],xsize=1,ysize=n_elements(faults),editable=0,$
  ;    column_widths=[20],scroll=0,sens=0)
  ;  widget_control,fault_id_lw,set_table_select=[-1,-1,-1,-1]
  ;
  ;
  ;  ;tab for the Axis status information
  ;  axis_status_base_lw=widget_base(tab_base_lw,/col,/base_align_center,title='Axis Status')
  ;  axis_status=['Axis enabled','Home complete','In position','Move active','Acceleration active',$
  ;    'Deceleration active','Pos. capture active','Current clamp','Brake output on',$
  ;    'Motion direction','Gearing/Camming active','Axis cal. active','Axis cal. enabled',$
  ;    'CW limit','CCW limit','Home limit','Marker input','Hall A input',$
  ;    'Hall B input','Hall C input','Sine error signal','Cosine error signal','Emergency stop input']
  ;
  ;  Axis_status_id_lw=widget_table(axis_status_base_lw,row_labels=axis_status,/no_column_headers,$
  ;    background_color=[0,255,0],xsize=1,ysize=n_elements(axis_status),editable=0,frame=1,$
  ;    column_widths=[30],scroll=0,sens=0)
  ;  widget_control,Axis_status_id_lw,set_table_select=[-1,-1,-1,-1]

  ;-------------------------------------------------------------------

  tab_base_soloist=widget_tab(soloist_control_base, uvalue='NULL')
  ;tab for the Soloist status information
  soloist_base_soloist=widget_base(tab_base_soloist,/col,/base_align_center,title='Soloist Status')
  status=['Pos. Command','Pos. Feedback','External Pos.',$
    'Analog In 0','Analog In 1','Analog Out 0','Analog Out 1',$
    'Digital In','Digital Out']

  val={poscmd:0d, pfbk:0d, extpos:0d, ain0:0., ain1:0., aout0:0., aout1:0., din:0ul, dout:0ul} ;just a placeholder for now. Update in soloist_fts_drive_status

  drive_status_id_soloist=widget_table(soloist_base_soloist,row_labels=status,/no_column_headers,/column_major,frame=1,$
    xsize=1,ysize=n_elements(status),editable=0,column_widths=[100],scroll=0,sens=0,value=val)

  widget_control,drive_status_id_soloist,set_table_select=[-1,-1,-1,-1]

  stage_base_soloist=0l
  step_field_soloist=obj_new()
  if debug then begin ;only display stage controls in debug mode
    x=widget_label(soloist_base_soloist,/align_center,value='Stage Control')
    stage_base_soloist=widget_base(soloist_base_soloist,/col,/base_align_center,frame=1)
    x=widget_button(stage_base_soloist,value='Home',uvalue='HOME')
    step_field_soloist=fsc_inputfield(stage_base_soloist,/long,value=1,title='Stage step size (um)',/cr_only,xsize=5,event_pro='rrcat_soloist_fts_Event',uvalue='STEP SIZE')
    base2=widget_base(stage_base_soloist,/row)
    x=widget_button(base2,value='Step -',uvalue='STEP -')
    x=widget_button(base2,value='Step +',uvalue='STEP +')
    x=widget_button(base2,value='Scan',uvalue='STEP_TOGGLE')
    x=widget_button(base2,value='Stop',uvalue='ABORT')
  endif


  ;tab for the Soloist fault information
  soloist_fault_base_soloist=widget_base(tab_base_soloist,/col,/base_align_center,title='Soloist Faults')
  ack_id_soloist=widget_button(soloist_fault_base_soloist,value='Acknowledge Fault',uvalue='ACK',/align_center)
  faults=['Position Error','Over Current Fault','CW Hardware Limit','CCW Hardware Limit',$
    'CW Software Limit','CCW Software Limit','Drive Fault',$
    'Position Feedback Fault','Velocity Feedback Fault','Hall Effect Input Fault',$
    'Max Vel Command Fault','ESTOP Fault','Velocity Error Fault','Task Fault',$
    'Probe Fault','Aux Fault','Safe Zone Fault','Motor Temp. Fault','Amplifer Temp. Fault']

  Fault_id_soloist=widget_table(soloist_fault_base_soloist,row_labels=faults,/no_column_headers,frame=1,$
    background_color=[0,255,0],xsize=1,ysize=n_elements(faults),editable=0,$
    column_widths=[20],scroll=0,sens=0)
  widget_control,fault_id_soloist,set_table_select=[-1,-1,-1,-1]


  ;tab for the Axis status information
  axis_status_base_soloist=widget_base(tab_base_soloist,/col,/base_align_center,title='Axis Status')
  axis_status=['Axis enabled','Home complete','In position','Move active','Acceleration active',$
    'Deceleration active','Pos. capture active','Current clamp','Brake output on',$
    'Motion direction','Gearing/Camming active','Axis cal. active','Axis cal. enabled',$
    'CW limit','CCW limit','Home limit','Marker input','Hall A input',$
    'Hall B input','Hall C input','Sine error signal','Cosine error signal','Emergency stop input']

  Axis_status_id_soloist=widget_table(axis_status_base_soloist,row_labels=axis_status,/no_column_headers,$
    background_color=[0,255,0],xsize=1,ysize=n_elements(axis_status),editable=0,frame=1,$
    column_widths=[30],scroll=0,sens=0)
  widget_control,Axis_status_id_soloist,set_table_select=[-1,-1,-1,-1]

  ;-------------------------------------------------------------------

  tab_base_stepper=widget_tab(stepper_control_base, uvalue='NULL')
  ;tab for the FTS control inputs
  control_base_stepper=widget_base(tab_base_stepper,/col,/base_align_center, title='Stepper Control')


  step_port_base = widget_base(control_base_stepper,/row,/base_align_left,/frame)
  step_connect=widget_button(step_port_base,value='Connect',uvalue='STEPPER_CONNECT',/align_center)
  x=widget_label(step_port_base,/align_right,value='Port:')
  stepper_port_field=widget_label(step_port_base,/align_left,$
    event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_PORT')
  parm_base_step=widget_base(control_base_stepper,/col,/base_align_right,/frame)

  motor_list = [ $
    'Intermediate', $  ; W
    'Reflection', $    ; X
    'Transmission', $  ; Y
    'FTS', $           ; A
    'MOC' $            ; B
    ]
  motor_id = widget_combobox(parm_base_step, value=string(motor_list),uvalue='STEPPER_MOTOR_SELECT', /align_center)
  setup_base_step=widget_base(parm_base_step,/col,/base_align_center,/frame)
  x=widget_label(setup_base_step,/align_center,value='Motor Setup')
  speed_field_step=fsc_inputfield(setup_base_step,/long,title='Speed (uSteps/s)',/cr_only,xsize=5,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_SPEED')
  accel_field_step=fsc_inputfield(setup_base_step,/long,title='Acceleration (uSteps/s^2)',/cr_only,xsize=5,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_ACCEL')
  current_field_step=fsc_inputfield(setup_base_step,/long,title='Current (mA)',/cr_only,xsize=8,decimal=3,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_CURRENT')
  ;  current_idle_field_step=fsc_inputfield(setup_base_step,/float,title='Idle Current (mA)',/cr_only,xsize=8,$
  ;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_CURRENT_IDLE')
  ;async_bgroup_step=CW_BGROUP(setup_base_step, '', LABEL_LEFT='Asynchronous', /nonexclusive, uvalue='STEPPER_ASYNC', SET_VALUE=1, /no_release)

  ;  limit_plus_setup_base_step=widget_base(setup_base_step,/col,/base_align_center,/frame)
  ;  x=widget_label(limit_plus_setup_base_step,/align_center,value='Limit +')
  ;  enabled_plus_bgroup_step=CW_BGROUP(limit_plus_setup_base_step, '', LABEL_LEFT='Enabled', /nonexclusive, uvalue='STEPPER_PLUS_ENABLED', SET_VALUE=1, /no_release)
  ;  limit_types = ['High', 'Low']
  ;  limit_high_low_plus_bgroup_step=CW_BGROUP(limit_plus_setup_base_step, limit_types, SET_VALUE=0, LABEL_LEFT='Stop', /ROW, /EXCLUSIVE, $
  ;    uvalue='STEPPER_PLUS_HIGH_LOW_LIMIT', /no_release)
  ;  limit_types = ['Soft', 'Hard']
  ;  soft_hard_limit_plus_bgroup_step=CW_BGROUP(limit_plus_setup_base_step, limit_types, SET_VALUE=0, LABEL_LEFT='Stop', /ROW, /EXCLUSIVE, $
  ;    uvalue='STEPPER_PLUS_HARD_SOFT_LIMIT', /no_release)
  ;
  ;  limit_minus_setup_base_step=widget_base(setup_base_step,/col,/base_align_center,/frame)
  ;  x=widget_label(limit_minus_setup_base_step,/align_center,value='Limit -')
  ;  enabled_minus_bgroup_step=CW_BGROUP(limit_minus_setup_base_step, '', LABEL_LEFT='Enabled', /nonexclusive, uvalue='STEPPER_MINUS_ENABLED', SET_VALUE=1, /no_release)
  ;  limit_types = ['High', 'Low']
  ;  limit_high_low_minus_bgroup_step=CW_BGROUP(limit_minus_setup_base_step, limit_types, SET_VALUE=0, LABEL_LEFT='Stop', /ROW, /EXCLUSIVE, $
  ;    uvalue='STEPPER_MINUS_HIGH_LOW_LIMIT', /no_release)
  ;  limit_types = ['Soft', 'Hard']
  ;  soft_hard_limit_minus_bgroup_step=CW_BGROUP(limit_minus_setup_base_step, limit_types, SET_VALUE=0, LABEL_LEFT='Stop', /ROW, /EXCLUSIVE, $
  ;    uvalue='STEPPER_MINUS_HARD_SOFT_LIMIT', /no_release)

  slew_directions = ['-', '+']
  slew_dir_id_step=CW_BGROUP(parm_base_step, slew_directions, SET_VALUE=0, LABEL_LEFT='Slew Direction', /ROW, /EXCLUSIVE, $
    uvalue='STEPPER_DIRECTION', /no_release)
  ;  slew_steps_field_step=fsc_inputfield(parm_base_step,/long,title='Slew Steps',/cr_only,xsize=8,$
  ;    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='STEPPER_STEPS')
  slew_id_step=widget_button(parm_base_step,value='SLEW',uvalue='STEPPER_SLEW',/align_center)
  stop_id_step=widget_button(parm_base_step,value='STOP',uvalue='STEPPER_STOP',/align_center)
  reset_id_step=widget_button(parm_base_step,value='RESET',uvalue='STEPPER_RESET',/align_center)
  ;status_id_step=widget_button(parm_base_step,value='STATUS',uvalue='STEPPER_STATUS',/align_center)
  step_pos_base = widget_base(parm_base_step,/row,/base_align_center,/align_center,/frame)
  x=widget_label(step_pos_base,value='Position:')
  stepper_pos_field=widget_label(step_pos_base, XSIZE=80)
  ;WIDGET_CONTROL, stepper_pos_field, TLB_GET_SIZE=tlb_size
  ;WIDGET_CONTROL, stepper_pos_field, XSIZE=80
  step_status_base = widget_base(parm_base_step,/row,/base_align_center,/align_center,/frame)
  x=widget_label(step_status_base,value='Status:')
  stepper_status_field=widget_label(step_status_base,XSIZE=80)
  ;-------------------------------------------------------------------

  ;  tab_base_stepper_limits=widget_tab(stepper_limit_control_base, uvalue='NULL')
  ;tab for the FTS control inputs
  x=widget_label(parm_base_step,value=' ', /align_center)
  x=widget_label(parm_base_step,value='Mirror Configuration', /align_center)
  limit_status_base_stepper=widget_base(parm_base_step,/col,/base_align_center,title='Stepper Limits')
  limit_status=['Intermediate HEB','Intermediate MCT','Reflection HEB','Reflection MCT',$
    'Transmission MCT','Transmission HEB','Martin Puplett','Michelson',$
    'Reflection/Transmission','Intermediate']

  limit_status_id_stepper=widget_table(limit_status_base_stepper,row_labels=limit_status,/no_column_headers,$
    background_color=[255,0,0],xsize=1,ysize=n_elements(limit_status),editable=0,frame=1,$
    column_widths=[30],scroll=0,sens=0)
  widget_control,limit_status_id_stepper,set_table_select=[-1,-1,-1,-1]

  ;-------------------------------------------------------------------
  tab_base_chopper=widget_tab(chopper_control_base, uvalue='NULL')
  ;tab for the FTS control inputs
  control_base_chopper=widget_base(tab_base_chopper,/col,/base_align_center, title='Chopper Control')

  chop_port_base = widget_base(control_base_chopper,/row,/base_align_left,/frame)
  chop_connect=widget_button(chop_port_base,value='Connect',uvalue='CHOPPER_CONNECT',/align_center)
  x=widget_label(chop_port_base,/align_right,value='Port:')
  chopper_port_field=widget_label(chop_port_base,/align_left,$
    event_pro='rrcat_soloist_fts_Event',uvalue='CHOPPER_PORT')
  blade_names = [ $
    ;    'MC1F2', $
    'MC1F10', $
    ;    'MC1F15', $
    ;    'MC1F30', $
    ;    'MC1F60', $
    ;    'MC1F100', $
    'MC1F10HP'];, $
  ;    'MC1F2P10', $
  ;    'MC1F6P10', $
  ;    'MC1F10A', $
  ;    'MC2F330', $
  ;    'MC1F47', $
  ;    'MC1F57B', $
  ;    'MC2F860', $
  ;    'MC2F5360']
  blade_field_chop=WIDGET_DROPLIST(control_base_chopper,value=blade_names,title='Blade Type',$
    uvalue='CHOPPER_BLADE')
  chop_blade_index = 0
  freq_field_chop=fsc_inputfield(control_base_chopper,/long,title='Freq. [Hz]',/cr_only,xsize=8,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='CHOPPER_FREQ')
  phase_field_chop=fsc_inputfield(control_base_chopper,/long,title='Phase [deg.]',/cr_only,xsize=8,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='CHOPPER_PHASE')
  cycle_field_chop=fsc_inputfield(control_base_chopper,/long,title='On Cycle [%]',/cr_only,xsize=8,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='CHOPPER_CYCLE')
  chopper_enable = 0
  enable_bgroup_chop=CW_BGROUP(control_base_chopper, '', LABEL_LEFT='Enable', /nonexclusive, uvalue='CHOPPER_ENABLE', SET_VALUE=0)
  chop_outputs = ['Target', 'Inner', 'Outer']
  output_select_base = widget_base(control_base_chopper,/col,/base_align_center, title='Chopper Control')
  output_select_chop=CW_BGROUP(output_select_base, chop_outputs, SET_VALUE=0, LABEL_LEFT='Output', /EXCLUSIVE, $
    uvalue='CHOPPER_OUTPUT', /no_release)
  chop_references = ['INT Outer', 'INT Inner', 'EXT Outer', 'EXT Inner']
  ref_select_base = widget_base(control_base_chopper,/col,/base_align_center, title='Chopper Control')
  ref_select_chop=CW_BGROUP(ref_select_base, chop_references, SET_VALUE=0, LABEL_LEFT='Reference', /EXCLUSIVE, $
    uvalue='CHOPPER_REFERENCE', /no_release, /col)
  x=widget_label(control_base_chopper,value='Actual Freq. [Hz]:')
  chopper_freq_field=widget_label(control_base_chopper, XSIZE=80)
  current_chopper_freq = 0L
  current_chopper_cycle = 0
  current_chopper_phase = 0
  current_chopper_blade = 0
  current_chopper_refoutfreq = 0L
  current_chopper_nharmonic = 0
  current_chopper_dharmonic = 0
  current_chopper_enbable = 0
  chopper_output_index = 0
  chopper_ref_output_index = 0
  chopper_blade_index = 0
  chopper_blade_index_old = 0
  ;-------------------------------------------------------------------
  tab_base_lia=widget_tab(lia_control_base, uvalue='NULL')
  ;tab for the FTS control inputs
  control_base_lia=widget_base(tab_base_lia,/col,/base_align_center, title='Lock-in Amplifier Settings')

  lia_port_base = widget_base(control_base_lia,/row,/base_align_left,/frame)
  lia_connect=widget_button(lia_port_base,value='Connect',uvalue='LIA_CONNECT',/align_center)
  x=widget_label(lia_port_base,/align_right,value='Port:')
  lia_port_field=widget_label(lia_port_base,/align_left,$
    event_pro='rrcat_soloist_fts_Event',uvalue='LIA_PORT')
  lia_status_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_status_base,value='LIA Status:')
  lia_status = '0'
  lia_status_field=widget_label(lia_status_base, XSIZE=80, VALUE=lia_status)
  lia_freq_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_freq_base,value='LIA Freq. (Hz):')
  lia_freq = '0'
  lia_freq_field=widget_label(lia_freq_base, XSIZE=80, VALUE=lia_freq)
  lia_tau_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_tau_base,value='LIA Time Const.:')
  lia_tau = '0'
  lia_tau_field=widget_label(lia_tau_base, XSIZE=80, VALUE=lia_tau)
  lia_sens_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_sens_base,value='LIA Sensitivity:')
  lia_sens = '0'
  lia_sens_field=widget_label(lia_sens_base, XSIZE=80, VALUE=lia_sens)
  lia_reserve_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_reserve_base,value='LIA Reserve:')
  lia_reserve = ''
  lia_reserve_field=widget_label(lia_reserve_base, XSIZE=80, VALUE=lia_reserve)
  lia_filter_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_filter_base,value='LIA Filter:')
  lia_filter = ''
  lia_filter_field=widget_label(lia_filter_base, XSIZE=80, VALUE=lia_filter)
  lia_phase_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_phase_base,value='LIA Phase (deg.):')
  lia_phase = ''
  lia_phase_field=widget_label(lia_phase_base, XSIZE=80, VALUE=lia_phase)
  lia_coupling_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_coupling_base,value='LIA Coupling:')
  lia_coupling = ''
  lia_coupling_field=widget_label(lia_coupling_base, XSIZE=80, VALUE=lia_coupling)
  lia_ground_base = widget_base(control_base_lia,/row,/base_align_center,/align_center,/frame)
  x=widget_label(lia_ground_base,value='LIA Gounding:')
  lia_ground = ''
  lia_ground_field=widget_label(lia_ground_base, XSIZE=80, VALUE=lia_ground)
  lia_save_settings=widget_button(control_base_lia,value='Save Settings',uvalue='LIA_SAVE_SETTINGS',/align_center)
  ;-------------------------------------------------------------------
  tab_base_relay=widget_tab(relay_control_base, uvalue='NULL')
  ;tab for the FTS control inputs
  control_base_relay=widget_base(tab_base_relay,/col,/base_align_center, title='Relay Control')

  relay_port_base = widget_base(control_base_relay,/row,/base_align_left,/frame)
  relay_connect=widget_button(relay_port_base,value='Connect',uvalue='RELAY_CONNECT',/align_center)
  x=widget_label(relay_port_base,/align_right,value='Port:')
  relay_port_field=widget_label(relay_port_base,/align_left,$
    event_pro='rrcat_soloist_fts_Event',uvalue='RELAY_PORT')
  relay_names = ['Stage (24V)', 'Preamp', 'Metrology', 'Internal BB', 'Hg Source', 'Steppers', 'Hg Cooloer']
  enable_bgroup_relay=CW_BGROUP(control_base_relay, relay_names, LABEL_LEFT='Relays On', /nonexclusive, uvalue='RELAY_ENABLE', SET_VALUE=0)
  x=widget_label(control_base_relay,value='Relay Status:')
  relay_status = '0'
  relay_status_field=widget_label(control_base_relay, XSIZE=80, VALUE=relay_status)
  ;-------------------------------------------------------------------

  status_main_base=widget_base(tlb,/row)

  status_main_base_file=widget_base(status_main_base,/col)
  x=widget_label(status_main_base_file,/align_center,value='File Parameters')
  file_base=widget_base(status_main_base_file,/col,/base_align_right,frame=1)
  x=widget_text(file_base,xsize=30,uname='filename',tab_mode=0,edit=0)
  base3=widget_base(file_base,/row)
  prefix_field=fsc_inputfield(base3,title='Prefix',xsize=12,$
    event_pro='rrcat_soloist_fts_Event',uvalue='PREFIX')
  number_field=fsc_inputfield(base3,/long,title='Number',xsize=5,$
    digits=4,event_pro='rrcat_soloist_fts_Event',uvalue='NUMBER')
  source_field=fsc_inputfield(file_base,title='Source',/cr_only,xsize=30,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='SOURCE')
  comment_field=fsc_inputfield(file_base,title='Comment',/cr_only,xsize=30,$
    /focus_events,event_pro='rrcat_soloist_fts_Event',uvalue='COMMENT')

  status_base=widget_base(status_main_base,/col,/frame,tab_mode=0)
  pos_base=widget_base(status_base,/row,/frame)
  x=widget_label(pos_base,value='Current Stage Position (cm OPD)')
  pos_id=widget_text(pos_base,xsize=10)
  ;           status_id=widget_text(status_base,xsize=35,ysize=12,/scroll,/wrap)  ;wrap causes problems with the calculation of # of lines.
  status_obj=BGStatus_Widget(status_base,label='Current Status:', xsize=35,$
    ysize=5,wrap=0,uval='STATUS')

  hk_base=widget_base(status_main_base,/col,/frame,tab_mode=0)
  fts_temp_1_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  x=widget_label(fts_temp_1_base,/align_left,value='FTS Temp. (K)')
  x=widget_text(fts_temp_1_base,xsize=30,uname='fts_temp_1',tab_mode=0,edit=0)

  fts_temp_2_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  x=widget_label(fts_temp_2_base,/align_left,value='FTS Temp. (K)')
  x=widget_text(fts_temp_2_base,xsize=30,uname='fts_temp_2',tab_mode=0,edit=0)

  fts_pressure_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  x=widget_label(fts_pressure_base,/align_left,value='FTS Pressure (torr)')
  x=widget_text(fts_pressure_base,xsize=30,uname='fts_pressure',tab_mode=0,edit=0)

  ;  ;  hk_base2=widget_base(status_main_base,/col,/frame,tab_mode=0)
  ;  det_temp_1_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  ;  x=widget_label(det_temp_1_base,/align_left,value='Det. Temp.')
  ;  x=widget_text(det_temp_1_base,xsize=30,uname='det_temp_1',tab_mode=0,edit=0)
  ;
  ;  det_temp_2_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  ;  x=widget_label(det_temp_2_base,/align_left,value='Det. Temp.')
  ;  x=widget_text(det_temp_2_base,xsize=30,uname='det_temp_2',tab_mode=0,edit=0)
  ;
  ;  det_temp_3_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  ;  x=widget_label(det_temp_3_base,/align_left,value='Det. Temp.')
  ;  x=widget_text(det_temp_3_base,xsize=30,uname='det_temp_3',tab_mode=0,edit=0)

  det_pressure_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  x=widget_label(det_pressure_base,/align_left,value='Det. Pressure (torr)')
  x=widget_text(det_pressure_base,xsize=30,uname='det_pressure',tab_mode=0,edit=0)

  det_temp_base=widget_base(hk_base,/row,/frame,tab_mode=0)
  x=widget_label(det_temp_base,/align_left,value='Det. Temp (K)')
  x=widget_text(det_temp_base,xsize=30,uname='det_temp',tab_mode=0,edit=0)

  setup_base=widget_base(status_main_base,/col,/frame,tab_mode=0)
  fts_type_base=widget_base(setup_base,/row,/frame,tab_mode=0)
  x=widget_label(fts_type_base,/align_left,value='FTS Selected')
  x=widget_text(fts_type_base,xsize=30,uname='fts_type',tab_mode=0,edit=0)

  fts_scan_mode_base=widget_base(setup_base,/row,/frame,tab_mode=0)
  x=widget_label(fts_scan_mode_base,/align_left,value='FTS Scanning Mode')
  x=widget_text(fts_scan_mode_base,xsize=30,uname='fts_scan_mode',tab_mode=0,edit=0)

  fts_metrology_base=widget_base(setup_base,/row,/frame,tab_mode=0)
  x=widget_label(fts_metrology_base,/align_left,value='FTS Metrology')
  x=widget_text(fts_metrology_base,xsize=30,uname='fts_metrology',tab_mode=0,edit=0)

  optics_type_base=widget_base(setup_base,/row,/frame,tab_mode=0)
  x=widget_label(optics_type_base,/align_left,value='Mode')
  x=widget_text(optics_type_base,xsize=30,uname='optics_type',tab_mode=0,edit=0)

  det_type_base=widget_base(setup_base,/row,/frame,tab_mode=0)
  x=widget_label(det_type_base,/align_left,value='Detector')
  x=widget_text(det_type_base,xsize=30,uname='det_type',tab_mode=0,edit=0)

  measurement_types = ['Sample', 'Reference']
  sample_reference_base=widget_base(status_main_base,/col,/frame,tab_mode=0)
  sample_reference=cw_bgroup(sample_reference_base,measurement_types,/exclusive,/row,$
    uvalue = "MEASUREMENT_TYPE", uname = "MEASUREMENT_TYPE", /no_release, $
    label_top='Measurement',/frame,set_value=0,/return_name)

  rt_types = ['Reflection', 'Transmission']
  ;  reflect_transmit=cw_bgroup(sample_reference_base,rt_types,/exclusive,/row,$
  ;    uvalue = "RT_TYPE", uname = "RT_TYPE", /no_release, $
  ;    /frame,set_value=0,/return_name)
 
  plot_base=widget_base(base,/col)
  ifg_plot = BGPlot_widget(plot_base, Title='Interferogram',UValue='IFG Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[-1,10],yrange=[-10,10], xtitle='OPD (cm)', ytitle='Amplitude (V)',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,/locky,renderer=renderer)

  spc_plot = BGPlot_widget(plot_base, Title='Spectrum',UValue='SPC Plot Event',$
    xsize=plot_xsize,ysize=plot_ysize,xrange=[0,100],yrange=[0,10], xtitle='Wavenumber (cm!E-1!N)', ytitle='Amplitude',$
    l_mouse_mode='zoom',m_mouse_mode='AutoScale Y',r_mouse_mode='unzoom',fontsize=12,/locky,renderer=renderer)

  chopper = 0
  chopper_port = 'COM6'
  IF simChopper EQ 0 THEN BEGIN
    chopper = rrcat_soloist_init_chopper_controller(port=chopper_port, baud=115200,data=8,parity='N',stop=1)
    ;chopper=obj_new('MC2000B',port='COM1',baud=115200,data=8,parity='N',stop=1)
    if not obj_valid(chopper) then begin
      result=dialog_message('Could not create MC2000B Chopper Controller object!',/err,title='Software Error')
      simChopper=1
      chopper_port = 'SIM'
    endif
    WIDGET_CONTROL, chopper_port_field, SET_VALUE=chopper_port
  ENDIF ELSE BEGIN
    chopper_port = 'SIM'
    WIDGET_CONTROL, chopper_port_field, SET_VALUE=chopper_port
  ENDELSE




;  relay = 0
;  relay_port = 'COM8'
;  IF simRelay EQ 0 THEN BEGIN
;    relay = rrcat_soloist_init_relay(port=relay_port, baud=9600,data=8,parity='N',stop=1)
;    ;relay=obj_new('kta223',port='COM1',baud=9600,data=8,parity='N',stop=1)
;    if not obj_valid(relay) then begin
;      result=dialog_message('Could not create KTA223 Relay controller object!',/err,title='Software Error')
;      simRelay=1
;      relay_port = 'SIM'
;      WIDGET_CONTROL, relay_port_field, SET_VALUE=relay_port
;    endif else begin
;      relay_status_data = relay->relayStatus()
;      ; New bits 03 July 2019
;      retVal = rrcat_parse_relay_string(relay_status_data)
;      result=dialog_message('Enabling Stage (24V), Metrology, and Steppers',/INFORMATION,title='Relay initialization')
;      new_relay_status = FIX(retVal) OR FIX(37)
;      retVal = relay->writeRelays(new_relay_status)
;      ; End new bits 03 July 2019
;      WIDGET_CONTROL, relay_port_field, SET_VALUE=relay_port
;    ENDELSE
;  ENDIF ELSE BEGIN
;    relay_port = 'SIM'
;    WIDGET_CONTROL, relay_port_field, SET_VALUE=relay_port
;  ENDELSE

  stepper = 0
  stepperMotors = REPLICATE({rrcat_motor_struct}, 5)
  foreach motorStr, stepperMotors, index do begin
    motorStr.motor = index
    ; TODO TRF this has been commented out
    ;IF index GT 2 THEN motorStr.motor = index+1  ; FTS Selection mirror is index 4 (M5)
    IF index GT 3 THEN motorStr.motor = index+1  ; FTS Selection mirror is index 3 (M4)
    ;motorStr.async = 1
    stepperMotors[index] = motorStr
  endforeach

  stepper_port = 'COM7'
  IF simStepper EQ 0 THEN BEGIN
    ;
    ; ;
    ; ; Open the communication port to the stepper controller and initialize to default
    ; settings:
    ;
    ; speed = 800 uSteps/s
    ; accel = 16000 uSteps/s^2
    ; current  = 300 mA
    ; ;
    stepper = rrcat_soloist_init_stepper_controller(stepperMotors=stepperMotors, port=stepper_port, baud=9600,data=8,parity='N',stop=1)
    if not obj_valid(stepper) then begin
      result=dialog_message('Could not create BC6D20 Stepper Controller object on port '+stepper_port+'!',/err,title='Connection Error')
      obj_destroy, stepper
      simStepper = 1
      stepper_port = 'SIM'
    endif
    WIDGET_CONTROL, stepper_port_field, SET_VALUE=stepper_port
  ENDIF ELSE BEGIN
    stepper_port = 'SIM'
    WIDGET_CONTROL, stepper_port_field, SET_VALUE=stepper_port
  ENDELSE


  relay = 0
  relay_port = 'COM8'
  IF simRelay EQ 0 THEN BEGIN
    relay = rrcat_soloist_init_relay(port=relay_port, baud=9600,data=8,parity='N',stop=1)
    ;relay=obj_new('kta223',port='COM1',baud=9600,data=8,parity='N',stop=1)
    if not obj_valid(relay) then begin
      result=dialog_message('Could not create KTA223 Relay controller object!',/err,title='Software Error')
      simRelay=1
      relay_port = 'SIM'
      WIDGET_CONTROL, relay_port_field, SET_VALUE=relay_port
    endif else begin
      relay_status_data = relay->relayStatus()
      ; New bits 03 July 2019
;      retVal = rrcat_parse_relay_string(relay_status_data)
;      result=dialog_message('Enabling Stage (24V), Metrology, and Steppers',/INFORMATION,title='Relay initialization')
;      new_relay_status = FIX(retVal) OR FIX(37)
;      retVal = relay->writeRelays(new_relay_status)
      ; End new bits 03 July 2019
      WIDGET_CONTROL, relay_port_field, SET_VALUE=relay_port
    ENDELSE
  ENDIF ELSE BEGIN
    relay_port = 'SIM'
    WIDGET_CONTROL, relay_port_field, SET_VALUE=relay_port
  ENDELSE

  lia = 0
  lia_port = 'COM9'
  IF simLia EQ 0 THEN BEGIN
    lia = rrcat_soloist_init_lia(port=lia_port, baud=9600,data=8,parity='N',stop=1)
    ; lia=obj_new('SR830',port=lia_port,baud=9600,data=8,parity='N',stop=1)
    if not obj_valid(lia) then begin
      result=dialog_message('Could not create SR830 Lock-in Amplifier object!',/err,title='Software Error')
      simLia=1
      lia_port = 'SIM'
    endif
    WIDGET_CONTROL, lia_port_field, SET_VALUE=lia_port
  ENDIF ELSE BEGIN
    lia_port = 'SIM'
    WIDGET_CONTROL, lia_port_field, SET_VALUE=lia_port
  ENDELSE

  ;create the Soloist object, but connect later
  soloist=obj_new('SoloistObj',debug=debug)
  if not obj_valid(soloist) then begin
    result=dialog_message('Could not create Soloist object!',/err,title='Software Error')
    widget_control, tlb, /destroy
    return
  endif
  
  fts_fields = { $
    ;    drive_status_id_sw:drive_status_id_sw,$
    ;    Axis_status_id_sw:Axis_status_id_sw,$
    ;    fault_id_sw:fault_id_sw,$
    tab_base_sw:tab_base_sw,$   ;used for disabling the control buttons.
    abort_id_sw:abort_id_sw,$
    speed_field_sw:speed_field_sw,$
    resolution_field_sw:resolution_field_sw,$
    ds_field_sw:ds_field_sw,$
    sym_button_sw:sym_button_sw,$
    nyquist_id_sw:nyquist_id_sw,$
    max_freq_field_sw:max_freq_field_sw,$
    scans_field_sw:scans_field_sw};,$
  ;    step_field_sw:step_field_sw,$ ;----------------------------- sw ^, lw \/
  ;    drive_status_id_lw:drive_status_id_lw,$
  ;    Axis_status_id_lw:Axis_status_id_lw,$
  ;    fault_id_lw:fault_id_lw,$
  ;    tab_base_lw:tab_base_lw,$   ;used for disabling the control buttons.
  ;    abort_id_lw:abort_id_lw,$
  ;    speed_field_lw:speed_field_lw,$
  ;    resolution_field_lw:resolution_field_lw,$
  ;    ds_field_lw:ds_field_lw,$
  ;    sym_button_lw:sym_button_lw,$
  ;    nyquist_id_lw:nyquist_id_lw,$
  ;    max_freq_field_lw:max_freq_field_lw,$
  ;    scans_field_lw:scans_field_lw};,$
  ;    step_field_lw:step_field_lw}

  housekeeping = { $
    fts_temp_1:0.,$
    fts_temp_2:0.,$
    fts_pressure:0.,$
    det_pressure:0.,$
    det_temp:0.}

  dio = { $
    metrology:0b, $
    scanning:0b, $
    bit2:0b, $
    bit3:0b}

  lia_settings={$
    freq:500.0,$  ; 500 Hz
    tau:4,$       ; 3 ms
    sens:0,$      ; 2 nV/fA
    reserve:1,$   ; Normal
    filter:0,$    ; 6dB/oct
    phase:360.0,$ ; 0 degrees
    coupling:0,$  ; AC coupling
    grounding:0}  ; Float

  a_channels = [0, 1, 2, 3, 4, 5, 6]

  maxTravels = [ $
    6300, $
    6300, $
    6300, $
    12795, $
    12920]

  info={tlb:tlb,$
    FTS_type:'MP',$		;this is the type of interferometer. 'MZ' for Mach Zehnder, otherwise Michelson. Stored in the settings file.
    fts_selected:'Martin-Puplett',$   ;this is the type of interferometer. 'MZ' for Mach Zehnder, otherwise Michelson. Stored in the settings file.
    SOLOIST_TYPE:'ML',$ ;the soloist model. MP supports PSO range -8M to 8M, CP supports 0 to 16M
    ADC_model:'MC1808X',$		;this is the ADC model number. Stored in the settings file.
    ADC_obj:obj_new(),$   ;the object for the DT7816
    ADC_IP:'DT7816-NAYLOR.uleth.ca',$   ;The IP address for the DT7816
    MC1808X_serial:'1CA58C4',$  ;The serial number of the MC1808X device
    a_channels:a_channels, $
    housekeeping:housekeeping,$
    measurement_type:'Sample',$
    measurement_types:measurement_types,$
    rt_type:'Reflection',$
    rt_types:rt_types,$
    optics:'Reflection',$
    det_type:'HEB',$
    soloist:soloist,$
    stepper:stepper,$
    lia:lia,$
    chopper:chopper,$
    relay:relay,$
    fts_fields:fts_fields,$
    timer_base:timer_base,$
    sai_timer_base:sai_timer_base,$
    status_timer_base:status_timer_base,$
    hk_timer_base:hk_timer_base,$
    scan_toggle_timer_base:scan_toggle_timer_base, $
    stepper_timer_base:stepper_timer_base, $
    ;sens_bases:[bar,file_base,parm_base_sw,stage_base_soloist,trig_base_sw,scan_base2_sw,parm_base_lw,trig_base_lw,scan_base2_lw,file_menu,option_menu],$	;bases to desensitize during a scan
    sens_bases:[bar,file_base,parm_base_sw,stage_base_soloist,trig_base_sw,scan_base2_sw,file_menu,option_menu],$ ;bases to desensitize during a scan
    ;status_id:status_id,$
    status_obj:status_obj,$
    drive_status_id:drive_status_id_soloist,$
    Axis_status_id:Axis_status_id_soloist,$
    fault_id:fault_id_soloist,$
    pos_id:pos_id,$
    debug:debug,$
    triggered:0,$
    dio:dio,$
    simStage:simStage,$
    simADC:simADC,$
    simStepper:simStepper,$
    simChopper:simChopper,$
    simLia:simLia,$
    simRelay:simRelay,$
    simHk:simHk,$
    simtime:0d,$
    simData:ptr_new(null),$
    start_id:start_id_sw,$
    scanning:0,$
    abort:0,$
    last_move:1, $
    fts_scan_mode:'Rapid Scan', $
    ifg:ptr_new(!null),$
    spc:ptr_new(!null),$
    wn:ptr_new(!null),$
    avg_ifg:ptr_new(!null),$
    avg_spc:ptr_new(!null),$
    spc_plot:spc_plot,$
    ifg_plot:ifg_plot,$
    plot_color:[0,255,0],$
    avg_color:[255,0,0],$
    hide_avg:0,$
    hide_current:0,$
    filename:'',$
    directory:working_dir,$	;default file directory
    ip:'10.28.1.41',$	; soloist IP address
    port:8000L,$	;soloist port
    fts_metrology:'PSO',$ ; FTS metrology method, PSO or Laser
    encoder:'MXH',$ ;	PSO encoder channel
    tab_base:tab_base_sw,$		;used for disabling the control buttons.
    abort_id:abort_id_sw,$
    prefix_field:prefix_field,$
    number_field:number_field,$
    source_field:source_field,$
    comment_field:comment_field,$
    speed_field:speed_field_sw,$
    resolution_field:resolution_field_sw,$
    ds_field:ds_field_sw,$
    scan_mode_base:scan_mode_base,$
    sai_base:sai_base,$
    sai_wait_field:sai_wait_field,$
    ;sai_samp_field:sai_samp_field,$
    ;sai_freq_field:sai_freq_field,$
    sym_button:sym_button_sw,$
    nyquist_id:nyquist_id_sw,$
    max_freq_field:max_freq_field_sw,$
    scans_field:scans_field_sw,$
    step_field:step_field_soloist,$
    widget_x_size:0l,$
    widget_y_size:0l,$
    widget_min_ysize:0l,$
    last_points:0l,$
    scans_remaining:0L,$

    tab_base_stepper:tab_base_stepper, $
    stepperMotors:stepperMotors,$
    motor_id:motor_id,$
    motor_list:motor_list, $
    selected_motor_index:0, $
    selected_motor:motor_list[0], $
    stepper_port_field:stepper_port_field, $
    stepper_pos_field:stepper_pos_field, $
    stepper_status_field:stepper_status_field, $
    stepper_port:stepper_port, $
    speed_field_step:speed_field_step, $
    accel_field_step:accel_field_step, $
    current_field_step:current_field_step, $
    slew_dir_id_step:slew_dir_id_step, $
    slew_id_step:slew_id_step, $
    reset_id_step:reset_id_step, $
    ;slew_steps_field_step:slew_steps_field_step, $
    ;async_bgroup_step:async_bgroup_step, $
    ;    enabled_plus_bgroup_step:enabled_plus_bgroup_step, $
    ;    limit_high_low_plus_bgroup_step:limit_high_low_plus_bgroup_step, $
    ;    soft_hard_limit_plus_bgroup_step:soft_hard_limit_plus_bgroup_step, $
    ;    enabled_minus_bgroup_step:enabled_minus_bgroup_step, $
    ;    limit_high_low_minus_bgroup_step:limit_high_low_minus_bgroup_step, $
    ;    soft_hard_limit_minus_bgroup_step:soft_hard_limit_minus_bgroup_step, $
    limit_status_id_stepper:limit_status_id_stepper, $
    startPos:0L, $
    maxTravels:maxTravels, $

    tab_base_chopper:tab_base_chopper, $
    control_base_chopper:control_base_chopper, $
    output_select_base:output_select_base, $
    ref_select_base:ref_select_base, $
    chop_blade_index:chop_blade_index, $
    chopper_port_field:chopper_port_field, $
    chopper_port:chopper_port, $
    blade_field_chop:blade_field_chop, $
    cycle_field_chop:cycle_field_chop, $
    freq_field_chop:freq_field_chop, $
    phase_field_chop:phase_field_chop, $
    enable_bgroup_chop:enable_bgroup_chop, $
    output_select_chop:output_select_chop, $
    ref_select_chop:ref_select_chop, $
    chopper_freq_field:chopper_freq_field, $
    current_chopper_freq:current_chopper_freq, $
    ;current_chopper_blade:current_chopper_blade, $
    ;chopper_blade_index:chopper_blade_index, $
    chopper_blade_index_old:chopper_blade_index_old, $
    current_chopper_cycle:current_chopper_cycle, $
    current_chopper_phase:current_chopper_phase, $
    current_chopper_refoutfreq:current_chopper_refoutfreq, $
    current_chopper_nharmonic:current_chopper_nharmonic, $
    current_chopper_dharmonic:current_chopper_dharmonic, $
    chopper_output_index:chopper_output_index, $
    chopper_ref_output_index:chopper_ref_output_index, $
    chopper_enable:chopper_enable, $

    tab_base_lia:tab_base_lia, $
    lia_port_field:lia_port_field, $
    lia_port:lia_port, $
    lia_status_field:lia_status_field, $
    lia_status:lia_status, $
    lia_freq:lia_freq, $
    lia_freq_field:lia_freq_field, $
    lia_tau:lia_tau, $
    lia_tau_field:lia_tau_field, $
    lia_sens:lia_sens, $
    lia_sens_field:lia_sens_field, $
    lia_reserve:lia_reserve, $
    lia_reserve_field:lia_reserve_field, $
    lia_filter:lia_filter, $
    lia_filter_field:lia_filter_field, $
    lia_phase:lia_phase, $
    lia_phase_field:lia_phase_field, $
    lia_coupling:lia_coupling, $
    lia_coupling_field:lia_coupling_field, $
    lia_ground:lia_ground, $
    lia_ground_field:lia_ground_field, $

    lia_settings:lia_settings, $

    tab_base_relay:tab_base_relay, $
    relay_port_field:relay_port_field, $
    relay_port:relay_port, $
    enable_bgroup_relay:enable_bgroup_relay, $
    relay_status_field:relay_status_field, $
    relay_status:relay_status, $
    relay_status_vector:INTARR(7), $

    plot_title:'',$ ;title to be used in the plot window.
    plot_avg:0,$		;flag to plot average IFG and SPC
    symmetrical:0,$	;set to center scan on ZPD. Max resolution might be changed.
    min_travel:-56.,$		;minimum mechanical stage travel (mm)
    max_travel:56.,$		;maximum mechanical stage travel (mm)
    pso_zero_position:0.,$ ;the location where the PSO counter is zero.
    home_speed:20.,$		;mechanical travel speed for home moves. (mm/s)
    acceleration:100.,$ ;default acceleration (mm/s)
    start_delay:0.,$  ;delay at start of scan for detector settling time.
    sampling_list:ptr_new(sampling_list),$	;the list of available sampling intervals in mm
    sampling_list_pso:ptr_new(sampling_list),$  ;the list of available sampling intervals in mm for PSO metrology
    sampling_list_laser:ptr_new(sampling_list_laser),$  ;the list of available sampling intervals in mm for laser metrology
    nyquist_list:ptr_new(nyquist_list),$	;the list of available nyquist frequencies
    nyquist_list_pso:ptr_new(nyquist_list),$  ;the list of available nyquist frequencies for PSO metrology
    nyquist_list_laser:ptr_new(nyquist_list_laser),$  ;the list of available nyquist frequencies for laser metrology
    gain:1,$		;[1,2,4,8]
    opd:ptr_new(!null),$	;opd grid in cm
    zpd:0.,$	;offset between ZPD and home, in mm MPD. EG if ZPD is 1.5 cm stage travel after home, then info.zpd=15
    zpd_sw:0.,$  ;offset between ZPD and home, in mm MPD for the RRCAT Michelson setup
    zpd_lw:0.,$  ;offset between ZPD and home, in mm MPD for the RRCAT Martin-Puplett setup
    refresh:.3,$	;plot refresh interval (s)
    sai_refresh:.1,$  ;plot refresh interval (s)
    status_refresh:1.,$	;status update rate (s)
    hk_refresh:300.,$ ;housekeeping update rate (s)
    stepper_refresh:0.1,$ ;stepper status update rate (s)
    scan_toggle_timer_refresh:0.5, $
    autoscale_spc:1,$	;autoscale SPC y axis
    autoscale_ifg_x:1,$	;autoscale IFG x axis
    autoscale_ifg_y:0,$ ;autoscale IFG y axis
    freq_units:'wn',$ ;either 'wn' or 'ghz' spectral units or 'hz' timebased frequency units
    samples_acquired:0,$
    buffer:64L,$	;ADC buffer length in samples
    det_samples:1l,$ ;Number of samples to acquire at each position in S&I mode. (This is 1 as we use the LIA)
    sai_wait_time:1.,$;Number of seconds to wait before sampling in S&I mode.
    max_freq:2500.,$
    freq_resp:1000.,$  ;max bolometer frequency response (Hz)
    clock_source:0b,$	;0 for external TTL, 1 for internal clock.
    clock_freq:0d }	;rate for the internal clock.

  ;find y size of widget minus the plot y size.
  geo=widget_info(tlb,/geometry)
  info.widget_y_size=geo.ysize-plot_ysize*2	;subtract the ysize of the two plot widgets
  info.widget_x_size=geo.xsize-plot_xsize	;subtract the xsize of the plot widgets

  geo=widget_info(tab_base_sw,/geometry)
  info.widget_min_ysize=geo.ysize+10



  Widget_Control, tlb, set_uvalue=info

  widget_control, tlb, /real, /show
  widget_control,tlb,get_uvalue=info
  RRCAT_SOLOIST_FTS_update_hk_status, info, /STEPPER

  id=widget_info(info.tlb,find_by_uname='optics_type')
  widget_control,id,set_value=STRTRIM(info.optics, 2)

  id=widget_info(info.tlb,find_by_uname='fts_type')
  widget_control,id,set_value=STRTRIM(info.fts_selected, 2)

  id=widget_info(info.tlb,find_by_uname='fts_scan_mode')
  widget_control,id,set_value=STRTRIM(info.fts_scan_mode, 2)

  id=widget_info(info.tlb,find_by_uname='fts_metrology')
  widget_control,id,set_value=STRTRIM(info.fts_metrology, 2)

  id=widget_info(info.tlb,find_by_uname='det_type')
  widget_control,id,set_value=STRTRIM(info.det_type, 2)

  if widget_info(tlb, /valid) then  XManager, 'rrcat_soloist_fts', tlb, /No_Block
  ;RRCAT_SOLOIST_FTS_update_filename, info
  IF info.simStepper NE 0 THEN BEGIN
    RRCAT_SOLOIST_FTS_DESENSITIZE,info,/STEPPER
  ENDIF
  IF info.simChopper NE 0 THEN BEGIN
    RRCAT_SOLOIST_FTS_DESENSITIZE,info,/CHOPPER
  ENDIF ELSE BEGIN
    RRCAT_SOLOIST_UPDATE_CHOPPER_FIELDS,info, /ALL
    rrcat_soloist_update_chopper_status, info, /FIELDS
  ENDELSE
  IF info.simLia NE 0 THEN BEGIN
    RRCAT_SOLOIST_FTS_DESENSITIZE,info,/LIA
  ENDIF

  IF info.simRelay EQ 0 THEN BEGIN
    RRCAT_SOLOIST_UPDATE_RELAY_FIELDS, info
    rrcat_soloist_update_relay_status, info
  ENDIF ELSE BEGIN
    RRCAT_SOLOIST_FTS_DESENSITIZE,info,/RELAY
  ENDELSE
  rrcat_soloist_change_fts_scan_mode, info, info.fts_scan_mode
  ;  IF info.simRelay NE 0 THEN BEGIN
  ;    RRCAT_SOLOIST_FTS_DESENSITIZE,info,/RELAY
  ;  ENDIF
  Widget_Control, tlb, set_uvalue=info
  WIDGET_CONTROL,info.hk_timer_base,timer=info.hk_refresh
end
