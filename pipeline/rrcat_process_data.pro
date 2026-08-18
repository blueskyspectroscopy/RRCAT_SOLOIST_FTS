PRO rrcat_process_data, RRCAT=RRCAT, PC=PC, ABS=ABS
  rt = 'Reflection'
  rootDir = 'V:\RRCAT\Data\2018_05_28\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(proceesedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot

  dataDir = 'HDPE_transmission_tes_standard_res'

  dataFiles = FILE_SEARCH(rootDir+ dataDir+'\', '*.ifg')
  IF STRPOS(dataDir, 'reflection') GT 0 THEN rt = 'Reflection' ELSE rt = 'Transmission'
  IF STRPOS(dataDir, 'hi_res') GT 0 THEN res = 'High' ELSE res = 'Standard'
  IF STRPOS(dataDir, 'Gold') EQ 0 THEN sample='Gold'
  IF STRPOS(dataDir, 'PS') EQ 0 THEN sample='Polystyrene'
  IF STRPOS(dataDir, 'Ecco') EQ 0 THEN sample='Eccosorb'
  IF STRPOS(dataDir, 'HDPE') EQ 0 THEN sample='HDPE'
  IF STRPOS(dataDir, 'heb') GT 0 THEN det='HEB'
  IF STRPOS(dataDir, 'tes') GT 0 THEN det='TES'
  IF STRPOS(dataDir, 'Reference') EQ 0 THEN sample='Reference'

  opd = []
  sig = []
  foreach dataFile, dataFiles, fIndex do begin
    fBase = file_basename(dataFile, '.ifg')
    ;IF STRPOS(fBase, 'HDPE') GT 0 THEN continue
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
  endforeach

  nScans = (SIZE(opd, /DIM))[1]
  shiftSig = sig
  for i=0, nScans-1 DO begin
    thisOpd = opd[*, i]
    thisSig = sig[*, i]
    zpd = 0.0
    minDif = MIN(ABS(thisOpd), whZPD)
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
  for i=0, nScans-1 DO begin
    thisOpd = opd[*, i]
    thisShiftSig = shiftSig[*, i]
    maxZPD = MAX(thisOpd)
    ds = 1./2./maxZPD
    thisWn = DINDGEN(nPoints)*ds
    thisSpec = (FFT(thisShiftSig, -1))[0:N_ELEMENTS(thisWn)-1]*nPoints

    wn = [[wn], [thisWn]]
    IF KEYWORD_SET(ABS) THEN BEGIN
      absSpec = ABS(thisSpec)
    ENDIF
    IF KEYWORD_SET(PC) THEN BEGIN
      if det EQ 'TES' THEN BEGIN
        wnMin = 300
        wnMax=600
      endif else begin
        wnMin = 30
        wnMax=60
      endelse
      ;      zoomplot, thisWn, -REAL_PART(thisSpec), obj_ref = pObj
      wh = WHERE(thisWn GT 300 AND thisWn LT 600)
      wnRange = thisWn[wh]
      thisSpecRange = thisSpec[wh]
      thePhase = ATAN(IMAGINARY(thisSpec)/REAL_PART(thisSpec))
      thisFit = LINFIT(wnRange, thePhase[wh], MEASURE_ERRORS=1./ABS(thisSpecRange)^2)
      ;      zoomplot, thisWn, (thePhase)*180./!PI, obj_ref = pObj
      ;      phaseFit = thisFit[0]+wnRange*thisFit[1]
      ;      pObj->add, wnRange, phaseFit*180./!PI, color = 'red'
      ;STOP
      theFullPhase = EXP(DCOMPLEX(DBLARR(N_ELEMENTS(thisWn)), -(thisFit[0]+thisWn*thisFit[1])))
      thisSpec = thisSpec*theFullPhase
      ;      pObj->add, thisWn, -REAL_PART(thisSpec), COLOR='yellow'
      ;      STOP
    ENDIF
    IF KEYWORD_SET(ABS) THEN BEGIN
      thisSpec = absSpec
    ENDIF
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
      fact = -1.
      ymin = -.5
      IF sample EQ 'Gold' THEN yMax = 11.0
      IF sample EQ 'Eccosorb' THEN yMax = 2.0
      IF sample EQ 'Polystyrene' THEN yMax = 2.0
      IF sample EQ 'HDPE' THEN yMax = 4.0
    endif else begin
      fact = 1.
      ymin = -5.
      xr = [0, 100]
      IF sample EQ 'Gold' THEN yMax = 100.0
      IF sample EQ 'Eccosorb' THEN yMax = 20.0
      IF sample EQ 'Polystyrene' THEN yMax = 40.0
      IF sample EQ 'HDPE' THEN yMax = 45.0
    endelse
  ENDIF else begin
    
    if det EQ 'TES' THEN BEGIN
      fact = -1.
            ymin = -0.5
      xr = [0, 800]
      IF sample EQ 'Reference' THEN yMax = 20.0
      IF sample EQ 'Polystyrene' THEN yMax = 2.0
      IF sample EQ 'HDPE' THEN yMax = 10.0
    endif else begin
      fact = 1.
      xr = [0, 100]
      ymin = -5.
      IF sample EQ 'Reference' THEN yMax = 200.0
      IF sample EQ 'Polystyrene' THEN yMax = 150.0
      IF sample EQ 'HDPE' THEN yMax = 200.0
    endelse
  Endelse
  IF KEYWORD_SET(ABS) THEN totalSpec = fact*totalSpec
  p = plot(thisWn, fact*totalSpec/nScans, $
    xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = xr, yrange=[ymin, yMax], $
    title = titleStr)
  fileName = dataDir
  IF KEYWORD_SET(ABS) THEN fileName = fileName + '_abs'
  fileName = fileName + '.jpg'
  outDataDir = proceesedDir+dataDir
  res = FILE_INFO(outDataDir)
  IF res.exists EQ 0 THEN FILE_MKDIR, outDataDir
  p.save, outDataDir+'\'+fileName
  outDataFile = fBase
  outDataFile = outDataFile + '_processed'
  IF KEYWORD_SET(ABS) THEN outDataFile = outDataFile + '_abs'
  IF KEYWORD_SET(PC) THEN outDataFile = outDataFile + '_pc'
  outDataFile = outDataFile + '.spc'
  WRITE_SPC,outDataDir+'\'+outDataFile,-totalSpec/nScans,thisWn[0],thisWn[1]-thisWn[0]
  STOP
END