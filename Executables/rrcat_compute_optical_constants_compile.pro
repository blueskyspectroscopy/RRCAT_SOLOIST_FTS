
;probably a good idea to call .RESET_SESSION first

pro RRCAT_COMPUTE_OPTICAL_CONSTANTS_compile
 
	routines=['BGPlot_widget',$
	  'RRCAT_COMPUTE_OPTICAL_CONSTANTS',$
	  'RRCAT_COMPUTE_OPTICAL_CONSTANTS_event',$
	  'RRCAT_COMPUTE_OPTICAL_CONSTANTS_update_output_plots',$
	  'rrcat_compute_n_and_k',$
	  'rrcat_compute_epsilon_and_alpha',$
		'read_spc', 'write_spc']
		
	RESOLVE_ROUTINE, routines, /COMPILE_FULL_FILE, /EITHER
	
	RESOLVE_ALL, class=['BGPlot',$
		'BGPlotGroup',$
		'BGPolyGroup','rrcat_soloist_fts_header', 'soloist_fts_header', 'spchdr', 'SUBHDR']

	if file_test(programrootdir()+'build',/dir) eq 0 then file_mkdir, programrootdir()+'build'
	
	save,/routines,filename=programrootdir()+'build\RRCAT_COMPUTE_OPTICAL_CONSTANTS.sav',/ver
	
	
end
