;
;
; 25 July 2019 (TRF): Modified so that average interferogram is also saved.
;

PRO RRCAT_AVERAGE_IFGMS

  fList = DIALOG_PICKFILE(FILTER='*.ifg', /MULTIPLE_FILES, TITLE='Please choose a list of files.')

  IF N_ELEMENTS(fList) EQ 1 and fList[0] EQ '' THEN BEGIN
    Result = DIALOG_MESSAGE( 'No files selected', $
      /ERROR, /center,TITLE='RRCAT_AVERAGE_IFGMS Error' )
    RETURN
  ENDIF
  ;opds = []
  ;sigs = []
  FOREACH f, fList, iFlist DO BEGIN
    dat = RRCAT_SOLOIST_FTS_READ_FILE(f)
    ;print, TYPE(dat)
    ;MESSAGE, STRING(TYPE(dat))
    IF TYPE(dat) NE 8 THEN BEGIN
      IF dat EQ -1 THEN dat = SOLOIST_FTS_READ_FILE(f)
    ENDIF
    if iFlist EQ 0 THEN BEGIN
      opd = dat.opd
      sigs = dat.signal
    endif ELSE BEGIN
      IF N_ELEMENTS(dat.opd) NE N_ELEMENTS(opd) THEN BEGIN
        Result = DIALOG_MESSAGE( 'Size mismatch. All interferograms must be the same length.', $
          /ERROR, /center,TITLE='RRCAT_AVERAGE_IFGMS Error' )
        RETURN
      ENDIF
      sigs = sigs + dat.signal
    endelse
  ENDFOREACH
  nFiles = N_ELEMENTS(fList)
  header=dat.header
  header.num_scans = nFiles
  avgSig = sigs/nFiles
  ;  dOpd = opd[1] - opd[0]
  ;
  ;  nHalf = N_ELEMENTS(avgSig)/2 + 1
  ;  wn = DINDGEN(nHalf)/(nHalf-1)/2./dOpd
  ;  avgSpec = ABS(FFT(avgSig, -1))
  ;  avgSpec = avgSpec[0:nHalf-1]
  points = N_ELEMENTS(avgSig)
  n=points + (points MOD 2) -1
  n=BEST_FFT_CLIP(n,n-32)
  IF (n MOD 2) EQ 0 THEN n+=1
  result=FFT_TO_SPECTRUM(avgSig[0:n-1]-MEAN(avgSig[0:n-1]), opd[0:n-1], avgSpec, wn)
  lastFile = fList[N_ELEMENTS(fList)-1]
  suggested_file = STRMID(lastFile, 0, STRLEN(lastFile)-4)
  suggested_file = suggested_file + '_avg_'+STRTRIM(N_ELEMENTS(fList), 2)
  outFile = DIALOG_PICKFILE(TITLE='Please choose a name for the output average spectrum file.', file = suggested_file+'.spc')
  WRITE_SPC,outFile,ABS(avgSpec),wn[0],wn[1]-wn[0], header=header, source=header.source, comment=header.comment

  outFile = DIALOG_PICKFILE(TITLE='Please choose a name for the output average interferogram file.', file = suggested_file+'.ifg')
  openw,lun,outFile,/get
;print,header.zpd
  writeu,lun,header
  writeu,lun,float(round(opd * 10000)/10000.) ;opd values, rounded to nearest micron to take care of floating point precision errors
  writeu,lun,float(avgSig)  

  free_lun,lun

  p = plot(wn, ABS(avgSpec), xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a.u.)', thick = 2)
  plotFile = DIALOG_PICKFILE(TITLE='Please choose a name for the plot file.', FILTER = '*.pdf', file = suggested_file+'.pdf')
  IF N_ELEMENTS(plotFile) GT 0 AND plotFile[0] NE '' THEN BEGIN
    p.save, plotFile
  ENDIF
  p.close


END