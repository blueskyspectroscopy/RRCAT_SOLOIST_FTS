
;+
; NAME:
;	RRCAT_SOLOIST_FTS_REALIZE
;
; PURPOSE:
;	This procedure is the event handler for the realization of the main widget.
;	This is the first thing that happens after the widget is created. The ADC
;	and Soloist are initialized and the plots are updated. This procedure is not
;	called by the user.
;
; CATEGORY:
;	SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_REALIZE, Id
;
; INPUTS:
;	Id:	The widget ID of the main base.
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
;   07 Jul 2019 (TRF): Added pop-ups to the miror initialization that will cancel the moves if need be.
;   10 Jul 2019 (TRF): Removed pop-ups to the miror initialization that will cancel the moves if need be.
;-

pro RRCAT_SOLOIST_FTS_REALIZE, id
  widget_control,id,get_uvalue=info

  ADC_connected=0 ;flag to verify that the ADC is connected
  Soloist_connected=0 ;flag to verify that the soloist is connected

  info.spc_plot->show
  info.ifg_plot->show

  result=RRCAT_SOLOIST_FTS_load_settings(info)		;load the last settings, update the entry fields

  if result eq 0 then begin
    widget_control,info.tab_base,sens=0
    x=dialog_message(['Error loading settings file!','Using default values- Check parameters!'],/err,dialog_parent=info.tlb)
    return
  endif

  ;******************
  ;Initialize ADC
  ;******************
  ADC_connected=rrcat_soloist_fts_init_adc(info)

  ;******************
  ;Initialize Soloist
  ;******************
  IF info.fts_metrology EQ 'PSO' THEN BEGIN
    soloist_connected=rrcat_soloist_fts_connect(info)
    info.nyquist_list = info.nyquist_list_pso
    info.sampling_list = info.sampling_list_pso
  ENDIF ELSE BEGIN
    soloist_connected=rrcat_soloist_fts_connect(info,/WINDOW)
    info.nyquist_list = info.nyquist_list_laser
    info.sampling_list = info.sampling_list_laser
  ENDELSE

  ;disable control buttons if ADC or soloist isn't connected
  if (soloist_connected eq 0 && info.simStage eq 0) || (adc_connected eq 0 && info.simADC eq 0) then begin
    widget_control,info.tab_base,sens=0
    ; TODO: Check that this is OK for RRCAT
  endif


  ; Setup the plots
  widget_control,hourglass=0

  info.ifg_plot->setAxisProperty,xrange=SOLOIST_FTS_POS_TO_OPD(info,[info.min_travel,info.max_travel])

  if info.simStage eq 0 && soloist_connected eq 1 then begin
    opd=SOLOIST_FTS_pos_to_opd(info,info.soloist->get_pos(err=err))	;current OPD position in cm
  endif else begin
    opd=SOLOIST_FTS_pos_to_opd(info,0)
  endelse

  SOLOIST_FTS_show_pos,info,opd

  SOLOIST_FTS_status,info,'Ready.'

  if info.debug then begin
    if !journal ne 0 then begin
      help,info,/str,output=output
      journal,output
    endif
  endif
  info.dio.scanning = 0b
  bitVal = RRCAT_SOLOIST_FTS_GET_DIO_BITVAL(info.dio)
  if ~info.simADC then result=RRCAT_SOLOIST_FTS_ADC_DOUT(bitVal,model=info.adc_model,obj=info.adc_obj)	;set the FTS status to 'Not waiting for trigger'.
  ;The status is 'Ready' when the Start Scan button is hit

  if info.simStepper EQ 0 then begin
    SOLOIST_FTS_status,info,'Configuring flip mirrors.'
;    rc = DIALOG_MESSAGE('About to initialize the FTS mirror. Continue with the move?', /QUESTION)
;    IF STRUPCASE(rc) EQ 'YES' THEN rrcat_set_fts_type, info, info.fts_selected
    SOLOIST_FTS_status,info,'FTS TYPE SET.'
;    rc = DIALOG_MESSAGE('About to initialize the MOC mirror. Continue with the move?', /QUESTION)
;    IF STRUPCASE(rc) EQ 'YES' THEN rrcat_set_optics_type, info, info.optics
    SOLOIST_FTS_status,info,'OPTICS TYPE SET.'
;    rc = DIALOG_MESSAGE('About to initialize the either the Intermediate, Reflection, or Transmission mirror. Continue with the move?', /QUESTION)
;    IF STRUPCASE(rc) EQ 'YES' THEN rrcat_set_det_type, info, info.optics, info.det_type
    SOLOIST_FTS_status,info,'DETECTOR TYPE SET.'
  endif

  if soloist_connected || info.simStage then begin
    widget_control,info.status_timer_base,timer=info.status_refresh	;timer to refresh the status fields
  endif
  SOLOIST_FTS_status,info,'Ready to begin.'

  widget_control,id,set_uvalue=info, /no_copy
end

