PRO rrcat_process_data_new_pc, RRCAT=RRCAT, PC=PC, ABS=ABS
  rt = 'Reflection'
  rootDir = 'V:\RRCAT\Data\2018_05_28\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot

  dataDir = 'Gold_reflection_tes_standard_res'

  dataFiles = FILE_SEARCH(rootDir+ dataDir+'\', '*.ifg')
  IF STRPOS(dataDir, 'reflection') GT 0 THEN BEGIN
    rt = 'Reflection'
    rtStr = 'refl' 
  ENDIF ELSE BEGIN
    rt = 'Transmission'
    rtStr = 'trans'
  ENDELSE
  IF STRPOS(dataDir, 'hi_res') GT 0 THEN BEGIN
    res = 'High'
    resStr = '0.055' 
  ENDIF ELSE BEGIN
    res = 'Standard'
    resStr = '0.2'
  ENDELSE
  IF STRPOS(dataDir, 'Gold') EQ 0 THEN sample='Gold'
  IF STRPOS(dataDir, 'PS') EQ 0 THEN sample='Polystyrene'
  IF STRPOS(dataDir, 'Ecco') EQ 0 THEN sample='Eccosorb'
  IF STRPOS(dataDir, 'HDPE') EQ 0 THEN sample='HDPE'
  IF STRPOS(dataDir, 'heb') GT 0 THEN det='HEB'
  IF STRPOS(dataDir, 'tes') GT 0 THEN det='TES'
  IF STRPOS(dataDir, 'Reference') EQ 0 THEN sample='Reference'
  
  
  opd = []
  sig = []
  firstTime = 1
  foreach dataFile, dataFiles, fIndex do begin
    fBase = file_basename(dataFile, '.ifg')
    ;IF STRPOS(fBase, '_PS') LT 0 THEN continue
    print, fBase
    IF STRPOS(fBase, 'avg') GT 0 THEN continue
    ;IF STRPOS(fBase, 'Ecco') GT 0 THEN continue
    IF KEYWORD_SET(RRCAT) THEN BEGIN
      dat = rrcat_soloist_fts_read_file(dataFile)
    ENDIF ELSE BEGIN
      dat = soloist_fts_read_file(dataFile)
    ENDELSE
    opd = [[opd], [dat.opd]]
    sig = [[sig], [dat.signal]]
    IF firstTime EQ 1 THEN BEGIN
      firstTime = 0
      avgSig = sig
    ENDIF ELSE BEGIN
      avgSig = avgSig + sig
    ENDELSE
  endforeach
  zpd_app = 0.0014
  nScans = (SIZE(opd, /DIM))[1]
  avgSig = avgSig/nScans
  minDif = MIN(ABS(dat.opd-zpd_app), whZPD)
  shiftAvgSig = SHIFT(avgSig, -whZPD)
  nPoints = N_ELEMENTS(shiftAvgSig)/2. + 1
  maxZPD = MAX(dat.opd)
  ds = 1./2./maxZPD
  avgWn = DINDGEN(nPoints)*ds
  avgSpec = (FFT(shiftAvgSig, -1))[0:N_ELEMENTS(avgWn)-1]*nPoints
  avgPhase = ATAN(IMAGINARY(avgSpec)/REAL_PART(avgSpec))
  if det EQ 'TES' THEN BEGIN
    wnMin = 230
    wnMax=680
  endif else begin
    wnMin = 20
    wnMax=60
  endelse
  wh = WHERE(avgWn GT wnMin AND avgWn LT wnMax)
  if det EQ 'TES' THEN BEGIN
    order = 3
  endif else begin
    order = 1
  endelse
  pFit = POLY_FIT(avgWn[wh], avgPhase[wh], order, MEASURE_ERRORS = 1./ABS(avgSpec[wh])^2, yFit = theFit)
  zoomplot, avgWn, avgSpec, obj_ref = sObj
  sObj->add, avgWn, IMAGINARY(avgSpec), color = 'red', thick=3

  zoomplot, avgWn, avgPhase, obj_ref = pObj
  pObj->add, avgWn[wh], theFit, color = 'red', thick=3

  ;  STOP
  shiftSig = sig
  ;STOP
  IF KEYWORD_SET(ABS) THEN BEGIN
    absSpec = ABS(avgSpec)
  ENDIF
  for i=0, nScans-1 DO begin
    thisOpd = opd[*, i]
    thisSig = sig[*, i]
    ;    zpd = 0.0
    ;    minDif = MIN(ABS(thisOpd), whZPD)
    ;    whZpd = WHERE(thisOpd EQ 0.0, whCount)
    thisShiftSig = SHIFT(thisSig, -whZPD)
    shiftSig[*, i] = thisShiftSig
    ;zoomplot, thisOpd, thisSig
    ;STOP
  endfor
  wn = []
  spec = []
  totalSpec = DBLARR(N_ELEMENTS(thisShiftSig)/2. + 1)
  nPoints = N_ELEMENTS(thisShiftSig)/2. + 1
  print, nScans, nPoints
  fact = -1.
  for i=0, nScans-1 DO begin
    thisOpd = opd[*, i]
    thisShiftSig = shiftSig[*, i]
    maxZPD = MAX(thisOpd)
    ds = 1./2./maxZPD
    thisWn = DINDGEN(nPoints)*ds
    thisSpec = (FFT(thisShiftSig, -1))[0:N_ELEMENTS(thisWn)-1]*nPoints

    wn = [[wn], [thisWn]]



    ;      zoomplot, thisWn, -REAL_PART(thisSpec), obj_ref = pObj
    wh = WHERE(thisWn GT 300 AND thisWn LT 600)
    pFit = REFORM(pFit)
    if det EQ 'TES' THEN BEGIN
      thisFit = pFit[0] + thisWn*pFit[1] + thisWn*thisWn*pFit[2] + $
        thisWn*thisWn*thisWn*pFit[3]; + $
      ;thisWn*thisWn*thisWn*thisWn*pFit[4] + $
      ;thisWn*thisWn*thisWn*thisWn*thisWn*pFit[5]
    endif else begin
      thisFit = pFit[0] + thisWn*pFit[1]
    endelse
    ;      zoomplot, thisWn, (thePhase)*180./!PI, obj_ref = pObj
    ;      phaseFit = thisFit[0]+wnRange*thisFit[1]
    ;      pObj->add, wnRange, phaseFit*180./!PI, color = 'red'
    ;STOP
    theFullPhase = EXP(DCOMPLEX(DBLARR(N_ELEMENTS(thisWn)), -(thisFit)))
    thisSpec = thisSpec*theFullPhase
    ;      pObj->add, thisWn, -REAL_PART(thisSpec), COLOR='yellow'
    ;      STOP


    ;    plot, thisWn, thisSpec, xrange = [100, 800], yrange=[-.5, 3.0]
    ;    STOP
    spec = [[spec], [thisSpec]]
    ;    zoomplot, thisWn, -REAL_PART(thisSpec), obj_ref = pObj
    ;    pObj->add, thisWn, IMAGINARY(thisSpec), color = 'red'
    ;    zoomplot, thisWn, (ATAN(IMAGINARY(thisSpec)/REAL_PART(thisSpec)))*180./!PI, obj_ref = pObj
    totalSpec = totalSpec + REAL_PART(thisSpec)
    ;    STOP
  endfor
  titleStr = sample + ' ' + rt + ' ' + det + ' ' + res + ' Resolution'
  IF rt EQ 'Reflection' THEN BEGIN
    if det EQ 'TES' THEN BEGIN
      xr = [0, 800]
      fact = 1.
      ymin = -.5
      IF sample EQ 'Gold' THEN yMax = 11.0
      IF sample EQ 'Eccosorb' THEN yMax = 2.0
      IF sample EQ 'Polystyrene' THEN yMax = 2.0
      IF sample EQ 'HDPE' THEN yMax = 4.0
    endif else begin
      fact = -1.
      ymin = -5.
      xr = [0, 100]
      IF sample EQ 'Gold' THEN yMax = 100.0
      IF sample EQ 'Eccosorb' THEN yMax = 20.0
      IF sample EQ 'Polystyrene' THEN yMax = 40.0
      IF sample EQ 'HDPE' THEN yMax = 45.0
    endelse
  ENDIF else begin

    if det EQ 'TES' THEN BEGIN
      fact = 1.
      ymin = -0.5
      xr = [0, 800]
      IF sample EQ 'Reference' THEN yMax = 20.0
      IF sample EQ 'Polystyrene' THEN yMax = 2.0
      IF sample EQ 'HDPE' THEN yMax = 10.0
    endif else begin
      fact = -1.
      xr = [0, 100]
      ymin = -5.
      IF sample EQ 'Reference' THEN yMax = 200.0
      IF sample EQ 'Polystyrene' THEN yMax = 150.0
      IF sample EQ 'HDPE' THEN yMax = 200.0
    endelse
  Endelse

  p = plot(thisWn, fact*totalSpec/nScans, thick=2, $
    xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = xr, yrange=[ymin, yMax], $
    title = titleStr)
  IF KEYWORD_SET(ABS) THEN BEGIN
    p=plot(thisWn, absSpec, color = 'green', thick=2, /overplot)
  ENDIF
  outDataFile = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
  pFile = outDataFile + '.jpg'
  IF KEYWORD_SET(ABS) THEN pFile = outDataFile + '_abs.jpg'
  outDataDir = processedRoot+det + '\'
  result = FILE_INFO(outDataDir)
  IF result.exists EQ 0 THEN FILE_MKDIR, outDataDir
  outDataDir = processedRoot+det + '\'+rt + '\'
  result = FILE_INFO(outDataDir)
  IF result.exists EQ 0 THEN FILE_MKDIR, outDataDir
  outDataDir = processedRoot+det + '\'+rt + '\'+sample + '\'
  result = FILE_INFO(outDataDir)
  IF result.exists EQ 0 THEN FILE_MKDIR, outDataDir
  outDataDir = processedRoot+det + '\'+rt + '\'+sample + '\'+ res + '_res\'
  result = FILE_INFO(outDataDir)
  IF result.exists EQ 0 THEN FILE_MKDIR, outDataDir
  p.save, outDataDir+'\'+pFile
  ;outDataFile = fBase
  outDataFile = outDataFile + '_processed'
  IF KEYWORD_SET(ABS) THEN outAbsDataFile = outDataFile + '_abs.spc'
  IF KEYWORD_SET(PC) THEN outFile = outFile + '_pc'
  outFile = outDataFile + '.spc'
  WRITE_SPC,outDataDir+'\'+outFile,fact*totalSpec/nScans,thisWn[0],thisWn[1]-thisWn[0]
  IF KEYWORD_SET(ABS) THEN WRITE_SPC,outDataDir+'\'+outAbsDataFile,absSpec,thisWn[0],thisWn[1]-thisWn[0]
;  STOP
END