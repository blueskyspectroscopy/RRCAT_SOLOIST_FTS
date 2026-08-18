
;+
; NAME:
;	RRCAT_SOLOIST_FTS_SAVE_LIA_SETTINGS
;
; PURPOSE:
;	This procedure saves lia settings to a file
;	so that the program state can be restored in the next session.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	RRCAT_SOLOIST_FTS_SAVE_LIA_SETTINGS, Info
;
; INPUTS:
;	Info:	The main infoblock from SOLOIST_FTS.pro
;	File: The filepath to save the settings in. Defaults to soloist_fts_settings.var
;
; MODIFICATION HISTORY:
; 	Written by:	Trevor Fulton, Jan 8 2018. Based on SOLOIST_FTS_SAVE_SETTINGS.pro
;   Written by: Trevor Fulton, May 18 2018. Based on RRCAT_SOLOIST_FTS_SAVE_SETTINGS.pro
;-

pro RRCAT_SOLOIST_FTS_save_lia_settings,info

   ; Establish error handler. When errors occur, the index of the
   ; error is returned in the variable Error_status:
   CATCH, Error_status
   ;This statement begins the error handler:
   IF Error_status NE 0 THEN BEGIN
      ;using the continue keyword will output the error to the journal but not stop processing.
      msg=!ERROR_STATE.MSG
      message, 'Error index: '+ strtrim(Error_status,2),/cont 
      message, 'Error message: '+ msg,/cont 
      CATCH, /CANCEL
      return
   ENDIF

	settings={$
      freq:0.0,$
      tau:0,$
      sens:0,$
      reserve:0,$
      filter:0,$
      phase:0.0,$
      coupling:0,$
      grounding:0}
        
  RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
  
	settings.freq=info.lia_settings.freq
	settings.tau=info.lia_settings.tau
	settings.sens=info.lia_settings.sens
	settings.reserve=info.lia_settings.reserve
	settings.filter=info.lia_settings.filter
	settings.phase=info.lia_settings.phase
	settings.coupling=info.lia_settings.coupling
	settings.grounding = info.lia_settings.grounding

  settings_file = info.optics + '_' + info.det_type + '_' + 'soloist_fts_lia_settings.xml'
  filename=ProgramRootDir()+settings_file
  IF info.debug NE 0 THEN SOLOIST_FTS_MESSAGE, info, 'Saving LIA settings to '+filename
  
  if float(!version.release) ge 8.3 then begin
    settings_hash=XML_hash(settings)
    !null = settings_hash.ToXml(string=xml_str)
  endif else begin
    ;this works for IDL 8.2 where the orderedhash object doesn't exist.
    obj=obj_new('XML_hash_82',settings)
    !null = obj->ToXml(string=xml_str)
  endelse

  openw,lun,filename,/get
  printf,lun,xml_str
  free_lun,lun

end

