;+
; NAME:
;	RRCAT_SOLOIST_FTS_load_lia_settings
;
; PURPOSE:
;	This procedure is used to restore the lia settings that were
;	saved by RRCAT_SOLOIST_FTS_SAVE_LIA_SETTINGS.pro.
;
; CATEGORY:
;	RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
;	result=RRCAT_SOLOIST_FTS_load_lia_settings(Info,File)
;
; INPUTS:
;	Info:	The main info block from RRCAT_SOLOIST_FTS.pro
;
; MODIFICATION HISTORY:
; 	Written by:	Brad Gom, Aug 1 2005.
;   Apr 11 2014 (BGG) - changed to use XML
;   Aug 29 2017 (BGG) - changed to function to return error status
;   2018 18 May (TRF) - Based on RRCAT_SOLOIST_FTS_load_settings
;-
function RRCAT_SOLOIST_FTS_load_lia_settings,info

  ; Establish error handler
  CATCH, Error_status
  IF Error_status NE 0 THEN BEGIN
    ;using the continue keyword will output the error to the journal but not stop processing.
    msg=!ERROR_STATE.MSG
    soloist_fts_message, info, 'Error loading settings!'
    soloist_fts_message, info, msg
    CATCH, /CANCEL
    return,0
  ENDIF
  lia_settings_file = info.optics + '_' + info.det_type + '_' + 'soloist_fts_lia_settings.xml'
  filename = Filepath(Root_Dir=ProgramRootDir(), lia_settings_file)
  IF info.debug NE 0 THEN SOLOIST_FTS_MESSAGE, info, 'Loading LIA settings from '+filename

  if file_test(filename,/regular,/read) eq 0 then begin
    IF info.debug NE 0 THEN SOLOIST_FTS_MESSAGE, info, filename + ' not found. Using default settings.'
    ;default file doesn't exist, use default values
    settings=hash({$
      freq:0.0,$
      tau:0,$
      sens:0,$
      reserve:0,$
      filter:0,$
      phase:0.0,$
      coupling:0,$
      grounding:0})
  endif else begin
    ;filename was found
    ;restore,filename
    openr,lun,filename,/get
    ; Read one line at a time, saving the result into one long string
    str = ''
    line = ''
    WHILE NOT EOF(lun) DO BEGIN
      READF, lun, line
      str = str+line
    ENDWHILE

    if float(!version.release) ge 8.3 then begin
      settings = XML_hash.FromXML(string=str)
    endif else begin
      ;this works for IDL 8.2 where the orderedhash object doesn't exist.
      obj=obj_new('XML_hash_82')
      settings = obj->FromXml(string=str)
    endelse

    ; Close the file and free the file unit
    FREE_LUN, lun
  endelse

  info.lia_settings.freq=settings['FREQ']
  info.lia_settings.tau=settings['TAU']
  info.lia_settings.sens=settings['SENS']
  info.lia_settings.reserve=settings['RESERVE']
  info.lia_settings.filter=settings['FILTER']
  info.lia_settings.phase=settings['PHASE']
  info.lia_settings.coupling=settings['COUPLING']
  info.lia_settings.grounding=settings['GROUNDING']

  IF OBJ_VALID(info.lia) THEN BEGIN
    rc = info.lia->setFreq(info.lia_settings.freq)
    rc = info.lia->setTau(info.lia_settings.tau)
    rc = info.lia->setSens(info.lia_settings.sens)
    rc = info.lia->setReserve(info.lia_settings.reserve)
    rc = info.lia->setFilter(info.lia_settings.filter)
    rc = info.lia->setPhase(info.lia_settings.phase)
    rc = info.lia->setCoupling(info.lia_settings.coupling)
    rc = info.lia->setGrounding(info.lia_settings.grounding)
    RRCAT_SOLOIST_LIA_UPDATE_FIELDS, info
  ENDIF ELSE BEGIN
    SOLOIST_FTS_MESSAGE, info, 'Cannot connect to the Lock-in Amplifier. Reset connection."
  ENDELSE

  return,1


end
