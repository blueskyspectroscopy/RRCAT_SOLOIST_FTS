
;probably a good idea to call .RESET_SESSION first

pro RRCAT_SPC_TO_CSV_compile

	routines=['RRCAT_SPC_TO_CSV', 'RRCAT_SOLOIST_FTS_READ_FILE', 'READ_SPC', 'WRITE_SPC', 'WRITE_CSV']
		
	RESOLVE_ROUTINE, routines, /COMPILE_FULL_FILE, /EITHER
	
	RESOLVE_ALL, class=['soloist_fts_header', 'rrcat_soloist_fts_header', 'spchdr', 'SUBHDR']
	
	if file_test(programrootdir()+'build',/dir) eq 0 then file_mkdir, programrootdir()+'build'
	
	save,/routines,filename=programrootdir()+'build\RRCAT_SPC_TO_CSV.sav',/ver
	
	
end
