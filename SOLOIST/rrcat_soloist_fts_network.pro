;+
; NAME:
;	RRCAT_SOLOIST_FTS_NETWORK
;
; PURPOSE:
;	This is a pop-up widget that enables options like the
;	working directory, port number, and file prefix to be set.
;	NOTE- you must fetch the info block from the main TLB after calling this routine.
;
; CATEGORY:
;	RRCAT_SOLOIST_FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_NETWORK, Info
;
; INPUTS:
;	Info: the pointer to the info block from the main program 
;
; KEYWORD PARAMETERS:
;	NONE
;
; MODIFICATION HISTORY:
; 	Written by:	BGG, May 9, 2009.
; 	07 Sept 2018, Modified for RRCAT
;-


PRO RRCAT_SOLOIST_FTS_NETWORK_event, ev

	WIDGET_CONTROL, ev.id, GET_UVALUE = uval
	WIDGET_CONTROL, ev.handler, GET_UVALUE=info, /NO_COPY		;this is the info block for this widget

	CASE uval of
		'DONE': BEGIN

			if widget_info(info.tlb,/valid) THEN BEGIN
				WIDGET_CONTROL, info.tlb, GET_UVALUE=main_info
				WIDGET_CONTROL, info.ip_id,     GET_VALUE = ip_str
				WIDGET_CONTROL, info.port_id,   GET_VALUE = port_val
				c=1

				ip=STRCOMPRESS( ip_str , /REMOVE_ALL)
				;check for valid IP address
				result=STREGEX(ip, '^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$',/bool)
				if result eq -1 then begin
					text='The ip must be of the form: 123.45.67.89'
					x=dialog_message(text,/error,title='Input Error',/center)
					SOLOIST_FTS_message, main_info, text
					WIDGET_CONTROL, ev.handler, SET_UVALUE=info, /NO_COPY		;this is the info block for this widget
					return
					endif else begin
					main_info.ip = ip
					SOLOIST_FTS_message, main_info, 'IP address changed to: '+ip
					endelse

				if port_val lt 1 or port_val gt 10000 then begin
					text='The port value must be between 1 and 10000'
					x=dialog_message(text,/error,title='Input Error',/center)
					SOLOIST_FTS_message, main_info, text
					WIDGET_CONTROL, ev.handler, SET_UVALUE=info, /NO_COPY		;this is the info block for this widget
					return
					endif else begin
					main_info.port = port_val
					SOLOIST_FTS_message, main_info, 'Port changed to: '+strtrim(port_val,2)
					endelse

				widget_control,main_info.tlb,set_uval=main_info
				RRCAT_SOLOIST_FTS_SAVE_SETTINGS,main_info		;save the settings in case the widget is killed.
				WIDGET_CONTROL, ev.handler, /destroy
	
				RETURN
				endif
			END
		ELSE: BEGIN ;unknown event
			message, "Unknown uvalue in SOLOIST_FTS_DIRECTORIES_event: "+strtrim( uval,2),/cont
		END
	ENDCASE

	WIDGET_CONTROL, ev.handler, SET_UVALUE=info, /NO_COPY
END

;-----------------------------------------------------------------------
PRO RRCAT_SOLOIST_FTS_NETWORK, info


	options_base = widget_base(title = 'Network Setup', /COLUMN, group_leader = info.tlb) ;, /MODAL)

	DEFAULT_FONT   = '';'Arial Black'

	field_base  = widget_base (options_base, /FRAME, /COLUMN, /base_align_right)

	ip_id = FSC_FIELD(field_base, TITLE = 'FTS IP Address (e.g. 192.168.0.100):', $
		labelFONT = DEFAULT_FONT, FIELDFONT = DEFAULT_FONT, $
		VALUE  = info.ip, /STRINGvalue, UVALUE = 'ip_ev')

	port_id = FSC_FIELD(field_base, TITLE = 'FTS Port Number (1-10000):', $
		labelFONT = DEFAULT_FONT, FIELDFONT = DEFAULT_FONT, $
		VALUE  = info.port, /LONGvalue, UVALUE = 'port_ev')


	button_base = widget_base(options_base, /ROW, /ALIGN_CENTER)
		done_id     = widget_button(button_base, value = 'OK',  uvalue = 'DONE', $
			FONT=DEFAULT_FONT, /ALIGN_CENTER)


	options_info = {$
		base_id:options_base, $
		tlb:info.tlb, $
		ip_id:ip_id, $
		port_id:port_id}

	WIDGET_CONTROL, options_base, SET_UVALUE=options_info, /NO_COPY
	WIDGET_CONTROL, options_base, /REALIZE

	XMANAGER, 'RRCAT_SOLOIST_FTS_NETWORK', options_base;, /NO_BLOCK

return
END
