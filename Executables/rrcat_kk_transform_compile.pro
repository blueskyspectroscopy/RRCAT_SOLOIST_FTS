
;probably a good idea to call .RESET_SESSION first

pro rrcat_kk_transform_compile

	routines=['BGPlot_widget',$
	  'rrcat_kk_transform',$
	  'rrcat_kk_transform_event',$
	  'rrcat_kk_update_plots',$
	  'rrcat_kk_update_output_plots',$
		'rrcat_kk_stitch_spectrum','read_spc', 'write_spc']
		
	RESOLVE_ROUTINE, routines, /COMPILE_FULL_FILE, /EITHER
	
	RESOLVE_ALL, class=['BGPlot',$
		'BGPlotGroup',$
    'BGPolyGroup','rrcat_soloist_fts_header', 'soloist_fts_header', 'spchdr', 'SUBHDR']

	if file_test(programrootdir()+'build',/dir) eq 0 then file_mkdir, programrootdir()+'build'
	
	save,/routines,filename=programrootdir()+'build\rrcat_kk_transform.sav',/ver
	
	
end
