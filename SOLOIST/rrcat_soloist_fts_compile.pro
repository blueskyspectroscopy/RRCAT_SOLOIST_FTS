
;probably a good idea to call .RESET_SESSION first

pro rrcat_soloist_fts_compile

	routines=['BGPlot_widget',$
	  'BGStatus_widget',$
	  'rrcat_soloist_fts',$
	  'rrcat_enable_fts_tab',$
	  'rrcat_read_spc',$
	  'rrcat_soloist_change_fts_scan_mode',$
	  'soloist_fts_adc_close',$
	  'soloist_fts_adc_collect',$
	  'rrcat_soloist_fts_adc_dout',$
	  'soloist_fts_adc_dump',$
	  'rrcat_soloist_fts_adc_dump',$
	  'soloist_fts_adc_din',$
	  'rrcat_soloist_fts_adc_init',$
	  'soloist_fts_adc_ready',$
	  'soloist_fts_adc_status',$
	  'soloist_fts_adc_stop',$
	  'rrcat_soloist_fts_connect',$
	  'rrcat_soloist_fts_desensitize',$
	  'soloist_fts_drive_status',$
	  'rrcat_soloist_fts_event',$
	  'rrcat_soloist_fts_get_dio_bitval',$
	  'soloist_fts_get_nyquist',$
	  'soloist_fts_get_sampling',$
	  'soloist_fts_handle_soloist_error',$
	  'soloist_fts_header_tree',$
	  'soloist_fts_help',$
	  'rrcat_soloist_fts_housekeeping',$
	  'rrcat_soloist_fts_init_adc',$
	  'rrcat_soloist_fts_kill',$
	  'rrcat_soloist_fts_limit_status',$
	  'soloist_fts_load_parms',$
	  'rrcat_soloist_fts_load_settings',$
	  'soloist_fts_message',$
	  'rrcat_soloist_fts_network',$
	  'soloist_fts_pos_to_opd',$
	  'rrcat_soloist_fts_process_sai_timer',$
	  'rrcat_soloist_fts_process_timer',$
	  'rrcat_soloist_fts_read_file',$
	  'rrcat_soloist_fts_realize',$
	  'rrcat_soloist_fts_save_settings',$
	  'rrcat_soloist_fts_sensitize',$
	  'rrcat_soloist_fts_set_nyquist_list',$
	  'soloist_fts_show_pos',$
	  'rrcat_soloist_fts_start_sai_scan',$
	  'rrcat_soloist_fts_start_scan',$
	  'soloist_fts_status',$
	  'soloist_fts_track_move',$
	  'rrcat_soloist_fts_update_filename',$
	  'rrcat_soloist_fts_update_hk_status',$
	  'soloist_fts_write_ascii',$
	  'rrcat_soloist_fts_write_file',$
		'rrcat_soloist_fts_write_spc',$
		'rrcat_soloist_stepper_move_motor',$
		'rrcat_parse_chopper_string',$
		'rrcat_soloist_convert_blade_index',$
		'rrcat_soloist_init_chopper_controller',$
		'rrcat_soloist_update_chopper_blade_fields',$
		'rrcat_soloist_update_chopper_fields',$
		'rrcat_soloist_update_chopper_status',$
		'rrcat_lia_translate_values',$
		'rrcat_soloist_fts_load_lia_settings',$
		'rrcat_soloist_fts_save_lia_settings',$
		'rrcat_soloist_init_lia',$
		'rrcat_soloist_lia_update_fields',$
		'rrcat_parse_relay_string',$
		'rrcat_soloist_init_relay',$
		'rrcat_soloist_relay_state',$
		'rrcat_soloist_update_relay_fields',$
		'rrcat_soloist_update_relay_status',$
		'rrcat_soloist_init_stepper_controller',$
		'rrcat_set_det_position',$
		'rrcat_get_det_position',$
		'rrcat_set_optics_position',$
		'rrcat_stepper_parse_string',$
		'rrcat_set_fts_position',$
		'rrcat_soloist_check_stepper_move_status',$
		'rrcat_stepper_reset_and_init',$
		'rrcat_soloist_stepper_start_move',$
		'rrcat_set_optics_type',$
		'rrcat_get_fts_position',$
		'rrcat_get_optics_position',$
		'rrcat_set_fts_type',$
		'rrcat_set_det_type',$
		'rrcat_update_stepper_motor_fields',$
		'rrcat_soloist_update_stepper_status',$
		'rrcat_stepper_make_command_string',$
		'rrcat_convert_step_status_to_string',$
		'rrcat_get_motor_string',$
		'rrcat_thermometer', $
		'convertFtsThermometry', $
		'volts2torr']
		
	RESOLVE_ROUTINE, routines, /COMPILE_FULL_FILE, /EITHER
	
	RESOLVE_ALL, class=['BGPlot',$
		'BGPlotGroup',$
		'BGPolyGroup',$
		'rrcat_soloist_fts_header',$
		'RRCAT_LIMIT_STRUCT',$
		'RRCAT_MOTOR_STRUCT',$
		'serial',$
		'spchdr',$
		'subhdr',$
		'bc6d20',$
		'kta223',$
		'mc2000b',$
		'sr830',$
		'MC1808X',$
		'DT7816',$
		'soloist_drive_status',$
		'soloistparmobj',$
		'soloistobj',$
		'linkedlist']

		if float(!version.release) ge 8.3 then begin
		  RESOLVE_ALL, class=['xml_hash']
		endif else begin
		  ;this works for IDL 8.2 where the orderedhash object doesn't exist.
      RESOLVE_ALL, class=['xml_hash_82']
		endelse
	
	if file_test(programrootdir()+'build',/dir) eq 0 then file_mkdir, programrootdir()+'build'
	
	save,/routines,filename=programrootdir()+'build\rrcat_soloist_fts.sav',/ver
	
	
end
