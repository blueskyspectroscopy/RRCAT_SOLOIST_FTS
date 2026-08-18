PRO rrcat_compute_reflection_transmission_old

  rootDir = 'V:\RRCAT\Data\2018_05_28\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot

  ;  sampleDir = 'HDPE_reflection_tes_standard_res'
  ;  refDir = 'Gold_reflection_tes_standard_res'

  sampleDir = 'PS_transmission_tes_standard_res'
  refDir = 'Reference_transmission_tes_standard_res'


  IF STRPOS(sampleDir, 'reflection') GT 0 THEN rt = 'Reflection' ELSE rt = 'Transmission'
  IF STRPOS(sampleDir, 'hi_res') GT 0 THEN res = 'High' ELSE res = 'Standard'
  IF STRPOS(sampleDir, 'PS') EQ 0 THEN sample='Polystyrene'
  IF STRPOS(sampleDir, 'Ecco') EQ 0 THEN sample='Eccosorb'
  IF STRPOS(sampleDir, 'HDPE') EQ 0 THEN sample='HDPE'
  IF STRPOS(sampleDir, 'heb') GT 0 THEN det='HEB'
  IF STRPOS(sampleDir, 'tes') GT 0 THEN det='TES'

  IF det EQ 'TES' THEN BEGIN
    sampleDataFiles = FILE_SEARCH(rootDir+ sampleDir+'\', '*_avg_50.spc')
    refDataFiles = FILE_SEARCH(rootDir+ refDir+'\', '*_avg_50.spc')
  ENDIF ELSE BEGIN
    sampleDataFiles = FILE_SEARCH(rootDir+ sampleDir+'\', '*_avg_100.spc')
    IF rt EQ 'Reflection' THEN BEGIN
      refDataFiles = FILE_SEARCH(rootDir+ refDir+'\', '*_avg_50.spc')
    ENDIF ELSE BEGIN
      refDataFiles = FILE_SEARCH(rootDir+ refDir+'\', '*_avg_100.spc')
    ENDELSE
  ENDELSE

  read_spc, sampleDataFiles[0], sampleWn, sampleSpec
  read_spc, refDataFiles[0], refWn, refSpec

  IF det EQ 'TES' THEN BEGIN
    xr = [0, 800]
    IF rt EQ 'Reflection' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-7, 7]
      IF sample EQ 'Polystyrene' THEN yr = [-0.5, 0.5]
    ENDIF
    IF rt EQ 'Transmission' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0.01, 0.01]
      IF sample EQ 'Polystyrene' THEN yr = [-2e-5, 10e-5]
    ENDIF
  ENDIF
  IF det EQ 'HEB' THEN BEGIN
    xr = [0, 100]
    IF rt EQ 'Reflection' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-7, 7]
      IF sample EQ 'Polystyrene' THEN yr = [-0.0015, 0.0015]
    ENDIF
    IF rt EQ 'Transmission' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-3, 3]
      IF sample EQ 'Polystyrene' THEN yr = [-2, 2]
    ENDIF
  ENDIF

  zoomplot, sampleWn, sampleSpec, obj_ref=pObj, xrange = xr
  pObj->add, refWn, refSpec, color = 'red'

  reflection = sampleSpec/refSpec
  zoomplot, sampleWn, reflection, xrange = xr
  STOP
  titleStr = sample + ' ' + rt + ' ' + det + ' ' + res + ' Resolution'

  p = plot(sampleWn, reflection, xrange = xr, yrange = yr, $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Sample/Reference', title = titleStr)
  pfileName = sampleDir
  pfileName = pfileName + '.jpg'
  outDataFile = rt + '_' + sample + '_' + det + '.spc'
  outDataDir = processedRoot+sampleDir+'\'
  res = FILE_INFO(outDataDir)
  IF res.exists EQ 0 THEN FILE_MKDIR, outDataDir
  p.save, outDataDir+'\'+pfileName

  WRITE_SPC,outDataDir+'\'+outDataFile,reflection,sampleWn[0],sampleWn[1]-sampleWn[0]
END