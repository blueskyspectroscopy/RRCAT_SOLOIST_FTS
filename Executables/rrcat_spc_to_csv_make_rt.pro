;+
; NAME:
; RRCAT_SPC_TO_CSV_MAKE_RT
;
; PURPOSE:
; This procedure compiles builds a stand-alone runtime IDL distribution of RRCAT_SPC_TO_CSV
;
; CATEGORY:
; RRCAT_SPC_TO_CSV
;
; CALLING SEQUENCE:
; RRCAT_SPC_TO_CSV_MAKE_RT
;
; OUTPUTS:
; A directory tree named RT with the IDL distibution and the RRCAT_SPC_TO_CSV files.
;
; MODIFICATION HISTORY:
;   Written by: Trevor Fulton, 11 Jul 2019
;
;-

pro RRCAT_SPC_TO_CSV_make_rt
  ;probably a good idea to call .RESET_SESSION first
  
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

  MAKE_RT, 'RRCAT_SPC_TO_CSV', root_dir+'RT', LOGFILE=root_dir+'RRCAT_SPC_TO_CSV_make_rt_log.txt', /OVERWRITE,$
    SAVEFILE=root_dir+'build\RRCAT_SPC_TO_CSV.sav', /VM , /IDL_ASSISTANT, WIN32=win32, WIN64=win64 ;, /LIN32, /MACINT32


  file_copy,'splash.bmp',root_dir+'RT\RRCAT_SPC_TO_CSV',/overwrite
  file_copy,'bss.ico',root_dir+'RT\RRCAT_SPC_TO_CSV',/overwrite


  print,'RRCAT_SPC_TO_CSV Runtime compiled and copied to: '+root_dir+'RT'
  print,'Move these files out of the IDL search tree to avoid conflicts with the .pro file names!!'

  cd,start_dir


end


 
