;+
; NAME:
; RRCAT_COMPUTE_OPTICAL_CONSTANTS_MAKE_RT
;
; PURPOSE:
; This procedure compiles builds a stand-alone runtime IDL distribution of RRCAT_COMPUTE_OPTICAL_CONSTANTS
;
; CATEGORY:
; RRCAT_COMPUTE_OPTICAL_CONSTANTS
;
; CALLING SEQUENCE:
; RRCAT_COMPUTE_OPTICAL_CONSTANTS_MAKE_RT
;
; OUTPUTS:
; A directory tree named RT with the IDL distibution and the RRCAT_COMPUTE_OPTICAL_CONSTANTS files.
;
; MODIFICATION HISTORY:
;   Written by: Trevor Fulton, 23 Aug 2019
;
;-

pro RRCAT_COMPUTE_OPTICAL_CONSTANTS_make_rt
  ;probably a good idea to call .RESET_SESSION first
  
  ;compile the save file
;  soloist_fts_compile

  root_dir=programrootdir()

  cd,root_dir,current=start_dir   ;start_dir is the initial working directory

  ;delete the RT subfolder
  file_delete,'RT2',/recursive,/allow_nonexistent,/quiet
  wait,2
  file_mkdir,'RT2'
  wait,2
  message,'Cleaned the RT2 folder',/info

  if !version.arch eq 'x86' then win32=1 else win32=0
  if !version.arch eq 'x86_64' then win64=1 else win64=0

  MAKE_RT, 'RRCAT_COMPUTE_OPTICAL_CONSTANTS', root_dir+'RT2', LOGFILE=root_dir+'RRCAT_COMPUTE_OPTICAL_CONSTANTS_make_rt_log.txt', /OVERWRITE,$
    SAVEFILE=root_dir+'build\RRCAT_COMPUTE_OPTICAL_CONSTANTS.sav', /VM , /IDL_ASSISTANT, WIN32=win32, WIN64=win64 ;, /LIN32, /MACINT32


  file_copy,'splash.bmp',root_dir+'RT2\RRCAT_COMPUTE_OPTICAL_CONSTANTS',/overwrite
  file_copy,'bss.ico',root_dir+'RT2\RRCAT_COMPUTE_OPTICAL_CONSTANTS',/overwrite


  print,'RRCAT_COMPUTE_OPTICAL_CONSTANTS Runtime compiled and copied to: '+root_dir+'RT2'
  print,'Move these files out of the IDL search tree to avoid conflicts with the .pro file names!!'

  cd,start_dir


end


 
