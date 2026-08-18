PRO rrcat_process_data_new_pc_05_30, RRCAT=RRCAT
  rt = 'Reflection'
  dateStr = '2018_05_30'
  rootDir = 'U:\RRCAT\Data\' + dateStr + '\'
  ;rootDir = 'V:\RRCAT\Data\2018_05_29\'
  ;rootDir = 'V:\RRCAT\Data\2018_05_28\'
  ;rootDir = 'V:\RRCAT\Data\2018_05_30\'
  processedRoot = rootDir + 'processed\'
  ;  dataDirRoot = rootDir + 'MCT\'
  ;dataDirRoot = rootDir + 'Pyro\'
  dataDirRoot = rootDir
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot


  ;  dataDir = 'Gold_Mirror'
  ;  dataDir = 'HDPE_refl'
  ;  dataDir = 'HDPE_trans'
  ;  dataDir = 'PS_refl'
  ;  dataDir = 'PS_trans'
  ;  dataDir = 'Ref_trans'
  pcFact = 1.
  ;  dataDirs = [ $
  ;    'Eccosorb_reflection_heb_standard_res', $
  ;    'Eccosorb_reflection_tes_hi_res', $
  ;    'Eccosorb_reflection_tes_standard_res', $
  ;    'Gold_reflection_heb_hi_res', $
  ;    'Gold_reflection_heb_standard_res', $
  ;    'Gold_reflection_tes_hi_res', $
  ;    'Gold_reflection_tes_standard_res', $
  ;    'HDPE_reflection_heb_standard_res', $
  ;    'HDPE_reflection_tes_standard_res', $
  ;    'HDPE_transmission_heb_standard_res', $
  ;    'HDPE_transmission_tes_hi_res', $
  ;    'HDPE_transmission_tes_standard_res', $
  ;    'PS_reflection_heb_standard_res', $
  ;    'PS_reflection_tes_standard_res', $
  ;    'PS_transmission_heb_standard_res', $
  ;    ;    'PS_transmission_tes_standard_res', $
  ;    'Reference_transmission_heb_hi_res', $
  ;    'Reference_transmission_heb_standard_res', $
  ;    'Reference_transmission_tes_hi_res', $
  ;    'Reference_transmission_tes_standard_res']



  ;  dataDirs = [ $
  ;    'Gold_Mirror', $
  ;    'HDPE_refl', $
  ;    'HDPE_trans', $
  ;    'PS_refl', $
  ;    'PS_trans', $
  ;    'Ref_trans']

  dataDirs = [ $
    ;  'Pyro_ref_trans_standard_res', $
;    'Pyro_reference_trans_standard_res'];, $
  ;    'HEB_reference_trans_standard_res', $
  ; 'HEB_ref_trans_hi_res'];, $
  ;      'TES_ref_trans_standard_res', $
      'TES_reference_trans_hi_res', $
      'TES_PS_trans_standard_res', $
      'TES_HDPE_trans_standard_res']

  foreach dataDir, dataDirs do begin

    IF STRPOS(dataDir, 'refl') GT 0 THEN BEGIN
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
    IF STRPOS(dataDir, 'Gold') EQ 0 THEN BEGIN
      sample='Gold'
      rt = 'Reflection'
      rtStr = 'refl'
    ENDIF
    IF STRPOS(STRUPCASE(dataDir), 'GOLD') GE 0 THEN sample='Gold'
    IF STRPOS(STRUPCASE(dataDir), 'PS') GE 0 THEN sample='Polystyrene'
    IF STRPOS(STRUPCASE(dataDir), 'ECCO') GE 0 THEN sample='Eccosorb'
    IF STRPOS(STRUPCASE(dataDir), 'HDPE') GE 0 THEN sample='HDPE'
    IF STRPOS(STRUPCASE(dataDir), 'HEB') GE 0 THEN det='HEB'
    IF STRPOS(STRUPCASE(dataDir), 'TES') GE 0 THEN det='TES'
    IF STRPOS(STRUPCASE(dataDirRoot), 'MCT') GE 0 THEN det='MCT'
    IF STRPOS(STRUPCASE(dataDirRoot), 'PYRO') GE 0 THEN det='Pyro'
    IF STRPOS(STRUPCASE(dataDir), 'MCT') GE 0 THEN det='MCT'
    IF STRPOS(STRUPCASE(dataDir), 'PYRO') GE 0 THEN det='Pyro'
    IF STRPOS(STRUPCASE(dataDir), 'REFER') GE 0 THEN sample='Reference'
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
        avgSig = avgSig + sig
      ENDELSE
    endforeach

    ;
    ;
    ; Position of apparent ZPD
    ;
    IF dateStr EQ '2018_05_28' THEN BEGIN
      IF det EQ 'TES' THEN BEGIN
        IF sample EQ 'HDPE' and rt EQ 'Transmission' and res EQ 'Standard' then zpd_app = 0.0014
        IF sample EQ 'HDPE' and rt EQ 'Transmission' and res EQ 'High' then zpd_app = 0.0012
        IF sample EQ 'HDPE' and rt EQ 'Reflection' then zpd_app = 0.0006
        IF sample EQ 'Polystyrene' and rt EQ 'Transmission' then zpd_app = 0.0018
        IF sample EQ 'Polystyrene' and rt EQ 'Reflection' then zpd_app = 0.0014
        IF sample EQ 'Eccosorb' then zpd_app = 0.0
        IF sample EQ 'Gold' and res EQ 'Standard' then zpd_app = 0.0012
        IF sample EQ 'Gold' and res EQ 'High' then zpd_app = 0.001
        IF sample EQ 'Reference' and res EQ 'Standard' then zpd_app = 0.0014
        IF sample EQ 'Reference' and res EQ 'High' then zpd_app = 0.0013
      ENDIF
      IF det EQ 'HEB' THEN BEGIN
        IF sample EQ 'Eccosorb' and res EQ 'Standard' then zpd_app = -0.0006
        IF sample EQ 'Eccosorb' and res EQ 'High' then zpd_app = -0.0006
        IF sample EQ 'HDPE' and rt EQ 'Transmission' then zpd_app = -0.0012
        IF sample EQ 'HDPE' and rt EQ 'Reflection' then zpd_app = -0.0016
        IF sample EQ 'Polystyrene' and rt EQ 'Transmission' then zpd_app = -0.0012
        IF sample EQ 'Polystyrene' and rt EQ 'Reflection' then zpd_app = -0.002
        IF sample EQ 'Gold' and res EQ 'Standard' then zpd_app = -0.0012
        IF sample EQ 'Gold' and res EQ 'High' then zpd_app = -0.0092
        IF sample EQ 'Reference' AND res EQ 'Standard' then zpd_app = -0.0011
        IF sample EQ 'Reference' AND res EQ 'High' then zpd_app = -0.0093
      ENDIF
    ENDIF
    IF dateStr EQ '2018_05_29' THEN BEGIN
      IF det EQ 'MCT' THEN BEGIN
        ;zpd_app = -0.0016
        IF sample EQ 'HDPE' and rt EQ 'Transmission' then zpd_app = -0.0016
        IF sample EQ 'HDPE' and rt EQ 'Reflection' then zpd_app = 0.0006

        IF sample EQ 'Polystyrene' and rt EQ 'Transmission' then zpd_app = -0.0016
        IF sample EQ 'Polystyrene' and rt EQ 'Reflection' then zpd_app = 0.0

        IF sample EQ 'Gold' then zpd_app = 0.0016
        IF sample EQ 'Reference' then zpd_app = -0.0016
      ENDIF
      IF det EQ 'Pyro' THEN BEGIN
        ;zpd_app = -0.0016
        IF sample EQ 'HDPE' and rt EQ 'Transmission' then zpd_app = -0.0016
        IF sample EQ 'HDPE' and rt EQ 'Reflection' then zpd_app = 0.0006

        IF sample EQ 'Polystyrene' and rt EQ 'Transmission' then zpd_app = -0.0016
        IF sample EQ 'Polystyrene' and rt EQ 'Reflection' then zpd_app = 0.0

        IF sample EQ 'Gold' then zpd_app = 0.0682
        IF sample EQ 'Reference' then zpd_app = 0.0678
      ENDIF
    ENDIF
    IF dateStr EQ '2018_05_30' THEN BEGIN
      IF det EQ 'TES' THEN BEGIN
        IF sample EQ 'Reference' and res EQ 'Standard' then zpd_app = -0.0002
        IF sample EQ 'Reference' and res EQ 'High' then zpd_app = -0.0002
        IF sample EQ 'HDPE' and res EQ 'Standard' then zpd_app = 0.0002
        IF sample EQ 'Polystyrene' and res EQ 'Standard' then zpd_app = 0.0004
      ENDIF
      IF det EQ 'HEB' THEN BEGIN

        IF sample EQ 'Reference' AND res EQ 'Standard' then zpd_app = -0.0013
        IF sample EQ 'Reference' AND res EQ 'High' then zpd_app = -0.0013
      ENDIF

      IF det EQ 'MCT' THEN BEGIN
        IF sample EQ 'Reference' AND res EQ 'Standard' then zpd_app = -0.0025
        IF sample EQ 'Reference' AND res EQ 'High' then zpd_app = -0.0093
      ENDIF
      IF det EQ 'Pyro' THEN BEGIN
        ;zpd_app = -0.0016
        IF sample EQ 'Reference' AND res EQ 'Standard' then zpd_app = -0.00
        IF sample EQ 'Reference' AND res EQ 'High' then zpd_app = -0.00
      ENDIF
    ENDIF

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
    ;
    ; Phase correction ranges
    ;
    if det EQ 'TES' THEN BEGIN
      wnMin = 230
      wnMax = 680
      IF sample EQ 'Gold' and res EQ 'High' then begin
        wnMin = 270
        wnMax = 410
      endif
      IF sample EQ 'Gold' and res EQ 'Standard' then begin
        wnMin = 270
        wnMax = 500
      endif
      IF sample EQ 'HDPE' and rt EQ 'Reflection' and res EQ 'Standard' then begin
        wnMin=380
        wnMax=600
      endif
      IF sample EQ 'HDPE' and rt EQ 'Transmission' and res EQ 'High' then begin
        wnMin=450
        wnMax=590
      endif
      IF sample EQ 'HDPE' and rt EQ 'Transmission' and res EQ 'Standard' then begin
        wnMin=450
        wnMax=590
      endif
      IF sample EQ 'Polystyrene' and rt EQ 'Reflection' and res EQ 'Standard' then begin
        wnMin=250
        wnMax=450
      endif

      IF sample EQ 'Polystyrene' and rt EQ 'Transmission' and res EQ 'Standard' then begin
        wnMin=115
        wnMax=145
      endif
      IF sample EQ 'Reference' and res EQ 'High' then begin
        wnMin=475
        wnMax=600
      endif
      IF sample EQ 'Reference' and res EQ 'Standard' then begin
        wnMin = 425
        wnMax = 560
      endif
      IF sample EQ 'HDPE' then pcFact = -1.
      IF sample EQ 'Polystyrene' then pcFact = -1.
      IF sample EQ 'HDPE' and rt EQ 'Transmission' AND res EQ 'High' then pcFact = 1.
      IF sample EQ 'HDPE' and rt EQ 'Transmission' AND res EQ 'Standard' then pcFact = 1.
      IF sample EQ 'Polystyrene' and rt EQ 'Reflection' AND res EQ 'Standard' then pcFact = 1.
      IF sample EQ 'Polystyrene' and rt EQ 'Transmission' AND res EQ 'Standard' then pcFact = 1.
    endif
    IF det EQ 'HEB' then  begin
      wnMin = 20
      wnMax = 60
      IF sample EQ 'HDPE' and rt EQ 'Reflection' AND res EQ 'Standard' then pcFact = -1.
      IF sample EQ 'Gold' and rt EQ 'Reflection' AND res EQ 'Standard' then pcFact = -1.
      IF sample EQ 'Gold' and rt EQ 'Reflection' AND res EQ 'High' then pcFact = -1.
      IF sample EQ 'Reference' and res EQ 'High' then pcFact = -1.
    endif
    if det EQ 'MCT' THEN BEGIN
      pcFact = -1.
      wnMin = 700
      wnMax=2200
      IF sample EQ 'HDPE' and rt EQ 'Reflection' AND res EQ 'Standard' then pcFact = 1.
    endif
    if det EQ 'Pyro' THEN BEGIN
      wnMin = 250
      wnMax=500
    endif

    IF dateStr EQ '2018_05_30' THEN BEGIN
      IF det EQ 'TES' THEN BEGIN
        IF sample EQ 'Reference' and res EQ 'High' then begin
          wnMin=475
          wnMax=600
        endif
        IF sample EQ 'Reference' and res EQ 'Standard' then begin
          wnMin = 425
          wnMax = 560
        endif
        IF sample EQ 'HDPE' and res EQ 'Standard' then begin
          wnMin = 425
          wnMax = 560
        endif
        IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
          wnMin = 425
          wnMax = 560
        endif
        IF sample EQ 'Reference' AND res EQ 'Standard' then pcFact = 1.0
        IF sample EQ 'Reference' AND res EQ 'High' then pcFact = 1.0
      ENDIF
      IF det EQ 'Pyro' THEN BEGIN
        wnMin = 425
        wnMax = 560
        pcFact = -1.0
      ENDIF
      IF det EQ 'HEB' THEN BEGIN
        IF sample EQ 'Reference' AND res EQ 'Standard' then pcFact = -1.0
        IF sample EQ 'Reference' AND res EQ 'High' then pcFact = -1.0
      ENDIF
    ENDIF
    wh = WHERE(avgWn GT wnMin AND avgWn LT wnMax)
    if det EQ 'TES' THEN BEGIN
      order=1
    endif
    IF det EQ 'HEB' then  begin
      order = 1
    endif
    if det EQ 'MCT' THEN BEGIN
      order = 1
    endif
    if det EQ 'Pyro' THEN BEGIN
      order = 1
    endif
    pFit = POLY_FIT(avgWn[wh], avgPhase[wh], order, MEASURE_ERRORS = 1./ABS(avgSpec[wh])^2, yFit = theFit)
    zoomplot, avgWn, avgSpec, obj_ref = sObj
    sObj->add, avgWn, IMAGINARY(avgSpec), color = 'red', thick=3

    zoomplot, avgWn, avgPhase, obj_ref = pObj
    pObj->add, avgWn[wh], theFit, color = 'red', thick=3

    zoomplot, dat.opd, avgSig, title = Sample + ' ' + rt + ' ' + det + ' ' + res
    ;    STOP
    shiftSig = sig
    STOP
    absSpec = ABS(avgSpec)
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
      IF N_ELEMENTS(REFORM(pFit)) EQ 2 then begin
        thisFit = pFit[0] + thisWn*pFit[1]
      ENDIF
      IF N_ELEMENTS(REFORM(pFit)) EQ 4 then begin
        thisFit = pFit[0] + thisWn*pFit[1] + thisWn*thisWn*pFit[2] + $
          thisWn*thisWn*thisWn*pFit[3]; + $
        ;thisWn*thisWn*thisWn*thisWn*pFit[4] + $
        ;thisWn*thisWn*thisWn*thisWn*thisWn*pFit[5]
      ENDIF
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
    titleStr = sample + ' ' + det + ' Resolution='+resStr+' cm$^{-1}$'
    IF rt EQ 'Reflection' THEN BEGIN
      if det EQ 'TES' THEN BEGIN
        xr = [0, 800]
        fact = 1.
        ymin = -.5
        IF sample EQ 'Gold' THEN yMax = 11.0
        IF sample EQ 'Eccosorb' THEN yMax = 2.0
        IF sample EQ 'Polystyrene' THEN yMax = 2.0
        IF sample EQ 'HDPE' THEN yMax = 4.0
      endif
      IF det EQ 'HEB' THEN BEGIN

        fact = -1.
        ymin = -5.
        xr = [0, 100]
        IF sample EQ 'Gold' THEN yMax = 100.0
        IF sample EQ 'Eccosorb' THEN yMax = 20.0
        IF sample EQ 'Polystyrene' THEN yMax = 40.0
        IF sample EQ 'HDPE' THEN yMax = 45.0
      endif
      IF det EQ 'MCT' THEN BEGIN

        fact = -1.
        ymin = -0.5
        xr = [0, 2500]
        IF sample EQ 'Gold' THEN yMax = 5.0
        IF sample EQ 'Eccosorb' THEN yMax = 20.0
        IF sample EQ 'Polystyrene' THEN yMax = 2.0
        IF sample EQ 'HDPE' THEN yMax = 2.0
      endif
      IF det EQ 'Pyro' THEN BEGIN

        fact = -1.
        ymin = -0.5
        xr = [0, 600]
        IF sample EQ 'Gold' THEN yMax = 10.0
        IF sample EQ 'Eccosorb' THEN yMax = 20.0
        IF sample EQ 'Polystyrene' THEN yMax = 2.0
        IF sample EQ 'HDPE' THEN yMax = 2.0
      endif
    ENDIF else begin

      if det EQ 'TES' THEN BEGIN
        fact = 1.
        ymin = -0.5
        xr = [0, 800]
        IF sample EQ 'Reference' THEN yMax = 25.0
        IF sample EQ 'Polystyrene' THEN yMax = 2.0
        IF sample EQ 'HDPE' THEN yMax = 10.0
      endif
      IF det EQ 'HEB' THEN BEGIN
        fact = -1.
        xr = [0, 100]
        ymin = -5.
        IF sample EQ 'Reference' THEN yMax = 200.0
        IF sample EQ 'Polystyrene' THEN yMax = 150.0
        IF sample EQ 'HDPE' THEN yMax = 200.0
      endif
      IF det EQ 'MCT' THEN BEGIN
        fact = -1.
        xr = [0, 2500]
        ymin = -0.5
        IF sample EQ 'Reference' THEN yMax = 4.0
        IF sample EQ 'Polystyrene' THEN yMax = 2.0
        IF sample EQ 'HDPE' THEN yMax = 2.0
      endif
      IF det EQ 'Pyro' THEN BEGIN
        fact = -1.
        xr = [0, 600]
        ymin = -0.5
        IF sample EQ 'Reference' THEN yMax = 10.0
        IF sample EQ 'Polystyrene' THEN yMax = 2.0
        IF sample EQ 'HDPE' THEN yMax = 2.0
      endif
    Endelse
    IF dateStr EQ '2018_05_30' THEN BEGIN
      IF det EQ 'Pyro' THEN BEGIN
        xr = [0, 2500]
        ymin = -0.5
        yMax = 6
      ENDIF
      IF det EQ 'HEB' THEN BEGIN
        xr = [0, 100]
        ymin = -5
        yMax = 100
      ENDIF
      IF sample EQ 'HDPE' THEN BEGIN
        xr = [0, 800]
        ymin = -0.5
        yMax = 20
      ENDIF
      IF sample EQ 'Polystyrene' THEN BEGIN
        xr = [0, 800]
        ymin = -0.5
        yMax = 3
      ENDIF
    ENDIF
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

  ;  STOP
END