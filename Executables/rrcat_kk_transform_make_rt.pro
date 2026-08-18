;+
; NAME:
; rrcat_kk_transform_MAKE_RT
;
; PURPOSE:
; This procedure compiles builds a stand-alone runtime IDL distribution of rrcat_kk_transform
;
; CATEGORY:
; rrcat_kk_transform
;
; CALLING SEQUENCE:
; rrcat_kk_transform_MAKE_RT
;
; OUTPUTS:
; A directory tree named RT with the IDL distibution and the rrcat_kk_transform files.
;
; MODIFICATION HISTORY:
;   Written by: Trevor Fulton, 24 Aug 2018
;
;-

pro rrcat_kk_transform_make_rt
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

  MAKE_RT, 'RRCAT_KK_TRANSFORM', root_dir+'RT', LOGFILE=root_dir+'rrcat_kk_transform_make_rt_log.txt', /OVERWRITE,$
    SAVEFILE=root_dir+'build\rrcat_kk_transform.sav', /VM , /IDL_ASSISTANT, WIN32=win32, WIN64=win64 ;, /LIN32, /MACINT32


  file_copy,'splash.bmp',root_dir+'RT\RRCAT_KK_TRANSFORM',/overwrite
  file_copy,'bss.ico',root_dir+'RT\RRCAT_KK_TRANSFORM',/overwrite


  print,'RRCAT_KK_TRANSFORM Runtime compiled and copied to: '+root_dir+'RT'
  print,'Move these files out of the IDL search tree to avoid conflicts with the .pro file names!!'

  cd,start_dir


end


 
