
;probably a good idea to call .RESET_SESSION first

pro rrcat_ratio_spectra_compile

	routines=['rrcat_ratio_spectra', 'READ_SPC', 'WRITE_SPC']
		
	RESOLVE_ROUTINE, routines, /COMPILE_FULL_FILE, /EITHER
	
	RESOLVE_ALL, class=['soloist_fts_header', 'rrcat_soloist_fts_header', 'spchdr', 'SUBHDR']

	if file_test(programrootdir()+'build',/dir) eq 0 then file_mkdir, programrootdir()+'build'
	
	save,/routines,filename=programrootdir()+'build\rrcat_ratio_spectra.sav',/ver
	
	
end
