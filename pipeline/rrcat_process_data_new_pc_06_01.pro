PRO rrcat_process_data_new_pc_06_01, RRCAT=RRCAT
  dateStr = '2018_06_02'
  rootDir = 'U:\RRCAT\Data\' + dateStr + '\'
  processedRoot = rootDir + 'processed\'

  dataDirRoot = rootDir
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  pcFact = 1.

  dataDirs = [ $
    ;'HEB_reference_trans_standard_res', $
    ;    'TES_reference_trans_standard_res', $
    ;    'TES_PS_trans_standard_res', $
    ;    'TES_HDPE_trans_standard_res', $
    ;    'Pyro_reference_trans_standard_res', $
    ;    'HEB_reference_trans_standard_res'];, $
    ;      'HEB_HDPE_trans_standard_res', $
    ;      'HEB_PS_trans_standard_res', $
    ;    'Pyro_reference_trans_standard_res', $
;    'Pyro_HDPE_trans_standard_res', $
;    'Pyro_PS_trans_standard_res']

;          'MCT_reference_trans_standard_res', $
;      'MCT_HDPE_trans_standard_res', $
;        'MCT_PS_trans_standard_res'];, $
  ;      'TES_Gold_refl_standard_res', $
  ;      'Pyro_Gold_refl_standard_res', $
  ;      'TES_HDPE_refl_standard_res', $
;        'Pyro_HDPE_refl_standard_res', $
  ;      'TES_null_refl_standard_res', $
  ;        'Pyro_null_refl_standard_res', $
  ;        'TES_PS_refl_standard_res', $
;          'Pyro_PS_refl_standard_res']
  ;    'MCT_Gold_refl_standard_res', $
  ;    'MCT_null_refl_standard_res', $
;      'MCT_HDPE_refl_standard_res', $
;      'MCT_PS_refl_standard_res'];, $
  ;    'HEB_Gold_refl_standard_res', $
  ;    'HEB_null_refl_standard_res', $
  ;    'HEB_HDPE_refl_standard_res', $
  ;    'HEB_PS_refl_standard_res']
      'MCT_reference_intermediate_standard_res']

  foreach dataDir, dataDirs do begin
    IF STRPOS(dataDir, 'refl') GT 0 THEN BEGIN
      rt = 'Reflection'
      rtStr = 'refl'
    ENDIF
    IF STRPOS(dataDir, 'trans') GT 0 THEN BEGIN
      rt = 'Transmission'
      rtStr = 'trans'
    ENDIF
    IF STRPOS(dataDir, 'inter') GT 0 THEN BEGIN
      rt = 'Intermediate'
      rtStr = 'int'
    ENDIF

    IF STRPOS(dataDir, 'hi_res') GT 0 THEN BEGIN
      res = 'High'
      resStr = '0.055'
    ENDIF ELSE BEGIN
      res = 'Standard'
      resStr = '0.2'
    ENDELSE
    IF STRPOS(dataDir, 'Gold') EQ 0 THEN BEGIN
      sample='Gold'
      rt = 'Reflection'
      rtStr = 'refl'
    ENDIF

    IF STRPOS(STRUPCASE(dataDir), 'GOLD') GE 0 THEN sample='Gold'
    IF STRPOS(STRUPCASE(dataDir), 'PS') GE 0 THEN sample='Polystyrene'
    IF STRPOS(STRUPCASE(dataDir), 'ECCO') GE 0 THEN sample='Eccosorb'
    IF STRPOS(STRUPCASE(dataDir), 'HDPE') GE 0 THEN sample='HDPE'
    IF STRPOS(STRUPCASE(dataDir), 'REFER') GE 0 THEN sample='Reference'
    IF STRPOS(STRUPCASE(dataDir), 'HEB') GE 0 THEN det='HEB'
    IF STRPOS(STRUPCASE(dataDir), 'TES') GE 0 THEN det='TES'
    IF STRPOS(STRUPCASE(dataDir), 'MCT') GE 0 THEN det='MCT'
    IF STRPOS(STRUPCASE(dataDir), 'PYRO') GE 0 THEN det='Pyro'
    IF STRPOS(STRUPCASE(dataDir), 'NULL') GE 0 THEN sample='null'

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
    resultsDir = rootDir + 'results\'
    resultsDir = resultsDir + rt + '\'
    result = FILE_INFO(resultsDir)
    IF result.exists EQ 0 THEN FILE_MKDIR, resultsDir

    opd = []
    sig = []
    firstTime = 1
    dataFiles = FILE_SEARCH(dataDirRoot+ dataDir+'\', '*.ifg')
    foreach dataFile, dataFiles, fIndex do begin
      fBase = file_basename(dataFile, '.ifg')
      ;IF STRPOS(fBase, 'pyro_ref') LT 0 THEN continue
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
        avgSig = avgSig + dat.signal
      ENDELSE
    endforeach

    ;
    ; observation specific parameters
    ;
    IF det EQ 'TES' THEN BEGIN
      xr = [0, 800]
      ymin = -0.5
      yMax = 15
      IF sample EQ 'Reference' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin=475
        wnMax=600
        yMax = 30
      ENDIF
      IF sample EQ 'Gold' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin=475
        wnMax=600
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0003
        wnMin = 425
        wnMax = 560
        yMax = 20
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 425
        wnMax = 560
        yMax = 2
      ENDIF
      IF sample EQ 'null' and res EQ 'Standard' then begin
        zpd_app = 0.0004
        wnMin = 425
        wnMax = 560
        yMax = 2
      ENDIF
    ENDIF
    IF det EQ 'HEB' THEN BEGIN
      xr = [0, 100]
      ymin = -5
      IF sample EQ 'Reference' AND res EQ 'Standard' then begin
        zpd_app = -0.0013
        wnMin= 20
        wnMax = 60
        yMax = 100
      ENDIF
      IF sample EQ 'Gold' AND res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin= 20
        wnMax = 60
        yMax = 200
        pcFact = -1.
      ENDIF
      IF sample EQ 'Reference' AND res EQ 'High' then begin
        zpd_app = -0.0013
        wnMin= 20
        wnMax = 60
        yMax = 100
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.00016
        wnMin= 20
        wnMax = 60
        yMax = 40
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.00016
        wnMin= 20
        wnMax = 60
        yMax = 40
        pcFact = -1.0
      ENDIF
    ENDIF

    IF det EQ 'MCT' THEN BEGIN
      xr = [0, 2500]
      ymin = -0.05
      IF rt EQ 'Intermediate' THEN BEGIN
        zpd_app = -0.0684
        wnMin = 1000
        wnMax = 1400
        yMax = 5
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Reference' AND res EQ 'Standard' then begin
        zpd_app = -0.0026
        wnMin = 1000
        wnMax = 1400
        yMax = 5
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Reference' AND res EQ 'High' then begin
        zpd_app = -0.0026
        wnMin = 1000
        wnMax = 1400
        yMax = 10
        pcFact = -1.0
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0026
        wnMin = 1000
        wnMax = 1400
        yMax = 4
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0026
        wnMin = 1000
        wnMax = 1400
        yMax = 4
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Gold' AND res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 8
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 0.5
        pcFact = -1.0
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 0.5
        pcFact = -1.0
      ENDIF
      IF sample EQ 'null' and res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 10
        pcFact = -1.0
      ENDIF
    ENDIF

    IF det EQ 'Pyro' THEN BEGIN
      xr = [0, 2500]
      ymin = -0.05
      IF sample EQ 'Gold' AND res EQ 'Standard' then begin
        zpd_app = -0.0004
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 1.5
      ENDIF
      IF sample EQ 'Reference' AND res EQ 'High' then begin
        zpd_app = -0.00
        wnMin = 425
        wnMax = 560
        pcFact = -1.0
        yMax = 1.5
      ENDIF
      IF sample EQ 'Reference' AND res EQ 'Standard' then begin
        zpd_app = -0.00
        wnMin = 425
        wnMax = 560
        pcFact = -1.0
        yMax = 5
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 0.2
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 0.2
      ENDIF
      IF sample EQ 'null' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 1.5
      ENDIF
    ENDIF

    nScans = (SIZE(opd, /DIM))[1]
    avgSig = avgSig/nScans
    minDif = MIN(ABS(dat.opd-zpd_app), whZPD)
    shiftAvgSig = SHIFT(avgSig, +(whZPD-2))
    nPoints = N_ELEMENTS(shiftAvgSig)/2. + 1
    maxZPD = MAX(dat.opd)
    ds = 1./2./maxZPD
    avgWn = DINDGEN(nPoints)*ds
    avgSpec = (FFT(shiftAvgSig, -1))[0:N_ELEMENTS(avgWn)-1]*nPoints
    avgPhase = ATAN(IMAGINARY(avgSpec)/REAL_PART(avgSpec))

    wh = WHERE(avgWn GT wnMin AND avgWn LT wnMax)
    order = 1
    pFit = POLY_FIT(avgWn[wh], avgPhase[wh], order, MEASURE_ERRORS = 1./ABS(avgSpec[wh])^2, yFit = theFit)
    zoomplot, avgWn, avgSpec, obj_ref = sObj
    sObj->add, avgWn, IMAGINARY(avgSpec), color = 'red', thick=3

    zoomplot, avgWn, avgPhase, obj_ref = pObj
    pObj->add, avgWn[wh], theFit, color = 'red', thick=3

    zoomplot, dat.opd, avgSig, title = Sample + ' ' + rt + ' ' + det + ' ' + res
    ; zoomplot, dat.opd, avgSig, title = Sample + ' ' + rt + ' ' + det + ' ' + res
    ;    STOP
    shiftSig = sig
    ;    p=plot(dat.opd, avgSig, title = Sample + ' ' + rt + ' ' + det + ' ' + res, $
    ;      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = [-0.2, 0.2])

    STOP
    absSpec = ABS(avgSpec)
    ;
    ; Apply phase correction to each scan and shift in prep for the FFT
    ;
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
    print, nScans, nPoints, N_ELEMENTS(thisShiftSig)

    for i=0, nScans-1 DO begin
      thisOpd = opd[*, i]
      thisShiftSig = shiftSig[*, i]
      maxZPD = MAX(thisOpd)
      ds = 1./2./maxZPD
      thisWn = DINDGEN(nPoints)*ds
      thisSpec = (FFT(thisShiftSig, -1))[0:N_ELEMENTS(thisWn)-1]*nPoints

      wn = [[wn], [thisWn]]

      wh = WHERE(thisWn GT 300 AND thisWn LT 600)
      pFit = REFORM(pFit)
      IF N_ELEMENTS(REFORM(pFit)) EQ 2 then begin
        thisFit = pFit[0] + thisWn*pFit[1]
      ENDIF
      IF N_ELEMENTS(REFORM(pFit)) EQ 4 then begin
        thisFit = pFit[0] + thisWn*pFit[1] + thisWn*thisWn*pFit[2] + $
          thisWn*thisWn*thisWn*pFit[3]; + $
      ENDIF
      ;      zoomplot, thisWn, (thePhase)*180./!PI, obj_ref = pObj
      ;      phaseFit = thisFit[0]+wnRange*thisFit[1]
      ;      pObj->add, wnRange, phaseFit*180./!PI, color = 'red'
      ;STOP
      theFullPhase = EXP(DCOMPLEX(DBLARR(N_ELEMENTS(thisWn)), -(thisFit)))
      thisSpec = thisSpec*theFullPhase
      ;      pObj->add, thisWn, -REAL_PART(thisSpec), COLOR='yellow'
      spec = [[spec], [thisSpec]]
      totalSpec = totalSpec + REAL_PART(thisSpec)
      ;    STOP
    endfor

    titleStr = sample + ' ' + det + ' Resolution='+resStr+' cm$^{-1}$'

    outDataFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
    p = plot(thisWn, pcFact*totalSpec/nScans, title = titleStr, $
      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = xr, yrange=[ymin, yMax])
    pFile = outDataFileRoot + '.jpg'
    p.save, outDataDir+'\'+pFile

    p=plot(thisWn, absSpec, $
      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = xr, yrange=[ymin, yMax])
    pFile = outDataFileRoot + '_abs.jpg'
    p.save, outDataDir+'\'+pFile
    p.save, resultsDir+'\'+pFile
    outFile = outDataFileRoot + '_processed.spc'
    WRITE_SPC,outDataDir+'\'+outFile,pcFact*totalSpec/nScans,thisWn[0],thisWn[1]-thisWn[0]

    outFile = outDataFileRoot + '_processed_abs.spc'
    WRITE_SPC,outDataDir+'\'+outFile,absSpec,thisWn[0],thisWn[1]-thisWn[0]
    WRITE_SPC,resultsDir+'\'+outFile,absSpec,thisWn[0],thisWn[1]-thisWn[0]
  endforeach
  STOP
END