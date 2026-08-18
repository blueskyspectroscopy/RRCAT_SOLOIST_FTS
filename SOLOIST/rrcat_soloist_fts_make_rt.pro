;+
; NAME:
; SOLOIST_FTS_MAKE_RT
;
; PURPOSE:
; This procedure compiles builds a stand-alone runtime IDL distribution of SOLOIST_FTS
;
; CATEGORY:
; SOLOIST_FTS
;
; CALLING SEQUENCE:
; SOLOIST_FTS_MAKE_RT
;
; OUTPUTS:
; A directory tree named RT with the IDL distibution and the SOLOIST_FTS files.
;
; MODIFICATION HISTORY:
;   Written by: Brad Gom, Jun 2015
;
;-

pro rrcat_soloist_fts_make_rt
  ;probably a good idea to call .RESET_SESSION first
  
  ;compile the save file
;  soloist_fts_compile

  root_dir=programrootdir()

  cd,root_dir,current=start_dir   ;start_dir is the initial working directory

  ;delete the RT subfolder
  file_delete,'RT',/recursive,/allow_nonexistent,/quiet
  wait,2
  file_mkdir,'RT'
  wait,2
  message,'Cleaned the RT folder',/info

  if !version.arch eq 'x86' then win32=1 else win32=0
  if !version.arch eq 'x86_64' then win64=1 else win64=0

  MAKE_RT, 'RRCAT_SOLOIST_FTS', root_dir+'RT', LOGFILE=root_dir+'make_rt_log.txt', /OVERWRITE,$
    SAVEFILE=root_dir+'build\RRCAT_SOLOIST_FTS.sav', /VM , /IDL_ASSISTANT, WIN32=win32, WIN64=win64 ;, /LIN32, /MACINT32

;  file_copy,'build\*','RT\SOLOIST_FTS',/overwrite,/recursive

  file_copy,'splash.bmp',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
  file_copy,'bss.ico',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
  file_copy,'rrcat_soloist_fts_settings.xml',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite

  ;copy the DT9803/4 dlm files
  ;get the path to the DLM folder
;  resolve_routine,'DT9803_DLM_test',/either
;  dlm_path=file_dirname(routine_filepath('DT9803_DLM_test',/either),/mark)
;  
;  file_copy,dlm_path+'DT9804_DLM.dll',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
;  file_copy,dlm_path+'DT9803_DLM.dll',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
;  file_copy,dlm_path+'DT9803_DLM.dlm',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
;  file_copy,dlm_path+'DT9804_DLM.dlm',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite

  ;Note: copy the OEM Setup folder of the DT OmniCD to the top level of the distrubition.

  ;copy the MC1808 dlm file
  ;get the path to the DLM folder
  resolve_routine,'MC1808X_DLM_test',/either
  dlm_path=file_dirname(routine_filepath('MC1808X_DLM_test',/either),/mark)

  file_copy,dlm_path+'MC1808X_DLM.dll',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
  file_copy,dlm_path+'MC1808X_DLM.dlm',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite

  ;copy the serial dlm files
  ;get the path to the DLM folder
  resolve_routine,'serial__define',/either
  dlm_path=file_dirname(routine_filepath('serial__define',/either),/mark)

  file_copy,dlm_path+'serial.dll',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite
  file_copy,dlm_path+'serial.dlm',root_dir+'RT\RRCAT_SOLOIST_FTS',/overwrite

  ;Note: copy the Instacal setup folder to the top level of the distrubition.

  print,'RRCAT_SOLOIST_FTS Runtime compiled and copied to: '+root_dir+'RT'
  print,'Move these files out of the IDL search tree to avoid conflicts with the .pro file names!!'

  cd,start_dir


end


 
