;+
; NAME:
;	RRCAT_SOLOIST_FTS_CONNECT
;
; PURPOSE:
;	This function connects to the Soloist controller. Called by RRCAT_SOLOIST_FTS_REALIZE. Returns 1 on success.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=RRCAT_SOLOIST_FTS_CONNECT(info)
;
; INPUTS:
;	info:	The main info block.
;
; MODIFICATION HISTORY:
; 	Written by:	TRF, Jun 15 2018
; 	Based on SOLOIST_FTS_CONNECT.
;-


function RRCAT_SOLOIST_FTS_CONNECT, info, WINDOW=WINDOW
	soloist_connected=0
	soloist_init:

	if info.debug then SOLOIST_FTS_message,info,'Initializing Soloist'
	SOLOIST_FTS_status,info,'Initializing Soloist...'
	widget_control,/hourglass
	err=0L
;	wait,1
	if info.simStage eq 0 then begin
		;stop any current motion and close. If not connected, this should continue quietly
		result=info.soloist->abort(err=err)
		result=info.soloist->close()

		if info.soloist->connect(info.ip,info.port,info.soloist_type) eq 1 then begin
			soloist_connected=1
			SOLOIST_FTS_message,info,'Connected to Soloist...'
			endif else begin
			widget_control,hourglass=0
			SOLOIST_FTS_message,info,'Soloist init failed: Could not connect to Soloist.'
			result=dialog_message(['Could not connect to soloist.','Verify connection to the Soloist module and hit OK.'],/info,title='Soloist Error')
			;if info.simStage eq 0 then SoloistClose, err=err
			result=dialog_message('Retry initialization?',/question,title='Stage error')
			if result eq 'Yes' then goto,soloist_init
;			obj_destroy,info.soloist  ;disable the drive, close the socket
;			Widget_Control, id, /destroy
;			return
			soloist_connected=0
			endelse
		endif

	if soloist_connected || info.simStage then begin		;Configure soloist if it is connected (or in simulation mode)
		SOLOIST_FTS_status,info,'Resetting Soloist...'
		if info.simStage eq 0 then begin
			result=info.soloist->reset(err=err)
			if err ne '' then begin
				result=dialog_message(['Error resetting Soloist:',err,'Retry initialization?'],/question,title='Soloist Error')
				if result eq 'Yes' then goto,soloist_init
;				Widget_Control, id, /destroy
;				return
				soloist_connected=0
				endif
			endif

		;This configures ALL of the configurable parameters, takes a second
		; and may be overkill, since they are saved to flash but may, be a nice
		;safety net, if the configuration manager is installed.

		SOLOIST_FTS_status,info,'Configuring...'

		home_Err=0l

		if info.simStage eq 0 then begin
		  result=info.soloist->enable(err=err)
;TODO- the commutation search seems to make the MZFTS slow to respond after enable
		  wait,10
			status = info.soloist->get_status(err=err)
			result = SOLOIST_FTS_handle_soloist_error(info, err)
			if result eq 0 then begin
				if Soloist_fts_load_parms(info,file) eq 0 then begin
					widget_control,hourglass=0
					if info.debug then SOLOIST_FTS_message,info,'Soloist init failed: '+string(err)
					result=info.soloist->close()
					result=dialog_message(['Failed to load parameters to Soloist!','Retry initialization?'],/question,title='Soloist error')
					if result eq 'Yes' then goto,soloist_init
					;Widget_Control, id, /destroy
					soloist_connected=0
					return,0
					endif
				if (status.homed) eq 0 then begin	;check if stage already homed (it shouldn't be)
				  ;configure to not wait for commands to finish
				  result=info.soloist->SET_WAIT_MODE('NOWAIT',err=err)
          result = SOLOIST_FTS_handle_soloist_error(info, err)
					SOLOIST_FTS_status,info,'Homing Stage...'
					;This function will block until home cycle complete.
					result=info.soloist->home(/block,err=err)	;a task fault here means the drive is disabled.
					;result = SOLOIST_FTS_handle_soloist_error(info, home_err)
					if err ne '' then begin
						SOLOIST_FTS_message,info, 'Soloist error: '+err
						SOLOIST_FTS_MESSAGE,info,'Home Failed!'
						soloist_fts_fault_message, info
						endif else begin
						SOLOIST_FTS_status,info,'Stage Homed'
						endelse
					endif else begin	;stage already homed
					SOLOIST_FTS_status,info,'Stage Homed'
					endelse
					;Initialize the PSO window
					if info.encoder eq 'Auxiliary' then aux=1 else aux=0
					if info.encoder eq 'MXH' then MXH=1 else MXH=0
					;
					; TRF EDIT!!!!
					; TODO: RRCAT hack
					MXH=1
					AUX=0
					;TODO- the pulse width should be in the configuration file.
					result=info.soloist->initialize_PSO_window(auxillary=aux, MXH=MXH, direction='fwd',width=10,zero_position=info.pso_zero_position, err=err, WINDOW=WINDOW)
          result=info.soloist->CONFIGURE_PSO_WINDOW(10,20,0.001,err=err)
					result=info.soloist->enable_PSO()
					if err ne '' then begin
					  SOLOIST_FTS_message,info, 'Soloist error: '+err
					  SOLOIST_FTS_MESSAGE,info,'Initialize PSO Window Failed!'
            soloist_fts_fault_message, info
					endif else begin
					  SOLOIST_FTS_status,info,'PSO Window Initialized'
					endelse
					
				endif else begin	;get_status failed
					widget_control,hourglass=0
					if info.debug then SOLOIST_FTS_message,info,'Soloist get_status failed: '+string(err)
					result=info.soloist->close()
					result=dialog_message(['Failed to connect to Soloist!','Retry initialization?'],/question,title='Soloist error')
					if result eq 'Yes' then goto,soloist_init
					;Widget_Control, id, /destroy
					;return
					soloist_connected=0
				endelse

			endif else begin	;info.simStage eq 0
			  ;SOLOIST_FTS_status,info,'Homing Stage...'
			  SOLOIST_FTS_status,info,'Stage Homed'
			  ;SOLOIST_FTS_status,info,'PSO Window Initialized'
      endelse
		endif	;soloist_connected || info.sim_stage

	return, soloist_connected 		;only return true if we actually connected, not if we're in simulation mode.

end

