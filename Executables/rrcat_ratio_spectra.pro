PRO RRCAT_RATIO_SPECTRA

  fList = DIALOG_PICKFILE(TITLE='Please choose a spectral file for the numerator.')

  IF N_ELEMENTS(fList) EQ 1 and fList[0] EQ '' THEN BEGIN
    Result = DIALOG_MESSAGE( 'No files selected', $
      /ERROR, /center,TITLE='RRCAT_RATIO_SPECTRA Error' )
    RETURN
  ENDIF
  READ_SPC, fList[0], num_wn, num_spec

  fList = DIALOG_PICKFILE(TITLE='Please choose a spectral file for the denominator.')

  IF N_ELEMENTS(fList) EQ 1 and fList[0] EQ '' THEN BEGIN
    Result = DIALOG_MESSAGE( 'No files selected', $
      /ERROR, /center,TITLE='RRCAT_RATIO_SPECTRA Error' )
    RETURN
  ENDIF
  READ_SPC, fList[0], den_wn, den_spec

  IF N_ELEMENTS(num_wn) NE N_ELEMENTS(den_wn) THEN BEGIN
    Result = DIALOG_MESSAGE( 'Size mismatch. Both spectra must be of the same length.', $
      /ERROR, /center,TITLE='RRCAT_RATIO_SPECTRA Error' )
    RETURN
  ENDIF
  wn = num_wn
  ratioSpec = num_spec/den_spec

  outFile = DIALOG_PICKFILE(TITLE='Please choose a name for the output file.')
  WRITE_SPC,outFile,ratioSpec,wn[0],wn[1]-wn[0]

  p = plot(wn, ratioSpec, xstyle = 1, ystyle = 1, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Ratio (a.u.)', thick = 2)
  plotFile = DIALOG_PICKFILE(TITLE='Please choose a name for the plot file.', FILTER = '*.pdf')
  IF N_ELEMENTS(plotFile) GT 0 AND plotFile[0] NE '' THEN BEGIN
    p.save, plotFile
  ENDIF

  p.close

END