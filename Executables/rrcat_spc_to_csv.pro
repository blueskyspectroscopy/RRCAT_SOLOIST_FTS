;
;
; 25 July 2019 (TRF): Added a check in case no header is present in the input file
;

PRO RRCAT_SPC_TO_CSV

  fileName = DIALOG_PICKFILE(FILTER=['*.ifg', '*.spc'], TITLE='Please choose a file to convert.')

  IF fileName EQ '' THEN BEGIN
    Result = DIALOG_MESSAGE( 'No files selected', $
      /ERROR, /center,TITLE='RRCAT_SPC_TO_CSV Error' )
    RETURN
  ENDIF
  fName = FILE_BASENAME(fileName)
  dirName = FILE_DIRNAME(fileName)
  fRoot = STRMID(fName, 0, STRLEN(fName)-4)
  fSuf = STRMID(fName, STRLEN(fName)-3, STRLEN(fName))
  goodFile = 0
  IF fSuf EQ 'spc' THEN BEGIN
    READ_SPC, fileName, x, y, header = h
    goodFile = 1
    outSuf = '_spec.csv'
    outH = ['wn (cm-1)', 'spectrum (a.u)']
  ENDIF
  IF fSuf EQ 'ifg' THEN BEGIN
    dat = RRCAT_SOLOIST_FTS_READ_FILE(fileName, header = h)
    goodFile = 1
    x = dat.opd
    y = dat.signal
    outSuf = '_ifgm.csv'
    outH = ['opd (cm)', 'signal (a.u)']
  ENDIF
  IF goodFile EQ 0 THEN BEGIN
    Result = DIALOG_MESSAGE( 'Unrecognized file suffix. Must be ifg or spc.', $
      /ERROR, /center,TITLE='RRCAT_SPC_TO_CSV Error' )
    RETURN
  ENDIF
  outFile = dirName +'\' + fRoot + outSuf

  outHeader = 'Source File: '+fileName

  IF N_ELEMENTS(h) NE 0 THEN BEGIN
    FOREACH tag, tag_names(h), iTag DO BEGIN
      new_line = tag + ': ' + STRTRIM(h.(iTag), 2)
      ;outHeader=outHeader+STRING(13B)+STRING(10B)+new_line
      outHeader=[outHeader,new_line]
    ENDFOREACH
  ENDIF

  WRITE_CSV, outFile, x, y, HEADER = outH, TABLE_HEADER = outHeader

END