PRO rrcat_compute_reflection_transmission

  rootDir = 'V:\RRCAT\Data\2018_05_29\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot

  ;  sampleDir = 'HDPE_reflection_tes_standard_res'
  ;  refDir = 'Gold_reflection_tes_standard_res'

  ;rt = 'Reflection'
  rt = 'Transmission'
  ;  sample='Polystyrene'
  sample='HDPE'
  det='MCT'
  res = 'Standard'

  IF rt EQ 'Reflection' GT 0 THEN BEGIN
    rtStr = 'refl'
  ENDIF ELSE BEGIN
    rtStr = 'trans'
  ENDELSE
  IF res EQ 'High' GT 0 THEN BEGIN
    resStr = '0.055'
  ENDIF ELSE BEGIN
    resStr = '0.2'
  ENDELSE

  IF rt EQ 'Reflection' then ref = 'Gold' ELSE ref = 'Reference'

  sampleDir = processedRoot + det + '\' + rt + '\' + sample + '\' + res + '_res\'
  refDir = processedRoot + det + '\' + rt + '\' + ref + '\' + res + '_res\'

  sampleFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
  refFileRoot = ref + '_' + rtStr + '_' + det + '_' + resStr + 'res'
  read_spc, sampleDir+sampleFile, sampleWn, sampleSpec
  read_spc, refDir+refFile, refWn, refSpec
  sampleFileAbs = sampleFileRoot + '_processed_abs.spc'
  refFileAbs = refFileRoot + '_processed_abs.spc'
  read_spc, sampleDir+sampleFileAbs, sampleWn, sampleSpecAbs
  read_spc, refDir+refFileAbs, refWn, refSpecAbs

  IF det EQ 'TES' THEN BEGIN
    xr = [0, 800]
    IF rt EQ 'Reflection' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0, 1]
      IF sample EQ 'Polystyrene' THEN yr = [-0, 1]
    ENDIF
    IF rt EQ 'Transmission' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0.0, 1.0]
      IF sample EQ 'Polystyrene' THEN yr = [-0.0, 1.0]
    ENDIF
  ENDIF
  IF det EQ 'HEB' THEN BEGIN
    xr = [0, 100]
    IF rt EQ 'Reflection' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0, 1]
      IF sample EQ 'Polystyrene' THEN yr = [-0, 1]
    ENDIF
    IF rt EQ 'Transmission' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0, 1]
      IF sample EQ 'Polystyrene' THEN yr = [-0, 1]
    ENDIF
  ENDIF

  IF det EQ 'MCT' THEN BEGIN
    xr = [0, 2500]
    IF rt EQ 'Reflection' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0, 1]
      IF sample EQ 'Polystyrene' THEN yr = [-0, 1]
    ENDIF
    IF rt EQ 'Transmission' THEN BEGIN
      IF sample EQ 'HDPE' THEN yr = [-0, 1]
      IF sample EQ 'Polystyrene' THEN yr = [-0, 1]
    ENDIF
  ENDIF

  zoomplot, sampleWn, sampleSpec, obj_ref=pObj, xrange = xr
  pObj->add, refWn, refSpec, color = 'red'

  reflection = sampleSpec/refSpec
  zoomplot, refWn, sampleSpecAbs/refSpecAbs, xrange = xr, yrange= yr, obj_ref=rObj
  rObj->add, sampleWn, reflection, color = 'green'
  ;STOP
  titleStr = sample + ' ' + rt + ' ' + det + ' ' + res + ' Resolution'
  outDataDir = sampleDir

  p = plot(sampleWn, reflection, xrange = xr, yrange = yr, thick = 2,$
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Sample/Reference', title = titleStr)
  pfile = sampleFileRoot + '_ratio.jpg'
  p.save, outDataDir+'\'+pfile

  p = plot(sampleWn, sampleSpecAbs/refSpecAbs, xrange = xr, yrange = yr, thick = 2,$
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Sample/Reference', title = titleStr)
  pfile = sampleFileRoot + '_ratio_abs.jpg'
  p.save, outDataDir+'\'+pfile
  outFile = sampleFileRoot + '.spc'
  WRITE_SPC,outDataDir+'\'+outDataFile,reflection,sampleWn[0],sampleWn[1]-sampleWn[0]

  outFile = sampleFileRoot + '_abs.spc'
  WRITE_SPC,outDataDir+'\'+outFile,sampleSpecAbs/refSpecAbs,sampleWn[0],sampleWn[1]-sampleWn[0]
END