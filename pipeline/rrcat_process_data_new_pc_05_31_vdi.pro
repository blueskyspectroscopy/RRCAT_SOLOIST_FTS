PRO rrcat_process_data_new_pc_05_31_VDI, RRCAT=RRCAT
  rt = 'Transmission'
  dateStr = '2018_05_31'
  ;dateStr = '2018_06_01'
  rootDir = 'U:\RRCAT\Data\' + dateStr + '\'
  ;rootDir = 'U:\RRCAT\Data\' + dateStr + '\'
  processedRoot = rootDir + 'processed\'
  result = FILE_INFO(processedRoot)
  IF result.exists EQ 0 THEN FILE_MKDIR, processedRoot
  
  dataDirRoot = rootDir
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  pcFact = 1.

  dataDirs = [ $
    'TES_VDI_trans_hi_res', $
    'Pyro_VDI_trans_hi_res']
;  dataDirs = [ $
;    'HEB_VDI_trans_hi_res']
  foreach dataDir, dataDirs do begin

    rt = 'Transmission'
    rtStr = 'trans'
    res = 'High'
    resStr = '0.055'
    sample = 'VDI'
    IF STRPOS(STRUPCASE(dataDir), 'TES') GE 0 THEN det='TES'
    IF STRPOS(STRUPCASE(dataDirRoot), 'PYRO') GE 0 THEN det='Pyro'
    IF STRPOS(STRUPCASE(dataDir), 'PYRO') GE 0 THEN det='Pyro'
    IF STRPOS(STRUPCASE(dataDir), 'HEB') GE 0 THEN det='HEB'

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
    ; observation specific parameters
    ;
    ymin = -0.5
    yMax = 6
    xr = [9.5, 12.5]
    IF det EQ 'TES' THEN BEGIN
      zpd_app = -0.0005
    ENDIF
    IF det EQ 'Pyro' THEN BEGIN
      zpd_app = -0.00
    ENDIF
    IF det EQ 'HEB' THEN BEGIN
      zpd_app = -0.00
    ENDIF
    nScans = (SIZE(opd, /DIM))[1]
    avgSig = avgSig/nScans
    nPoints = N_ELEMENTS(avgSig)/2. + 1
    maxOPD = MAX(dat.opd)
    ds = 1./2./maxOPD


    ;
    ; Apply phase correction to each scan and shift in prep for the FFT
    ;
    wn = []
    spec = []
    pcSpecs = DBLARR(nPoints)
    theseSpecs = DBLARR(nPoints)
    nPointsPad = nPoints*16L
    theseSpecsPad = DBLARR(nPointsPad)
    whRange = xr
    order=1
    IF det EQ 'TES' THEN BEGIN
      yr = [-5e3, 3e4]
      pcFact = -1.
    ENDIF ELSE BEGIN
      yr = [-5e3, 2e4]
      pcFact = 1.
    ENDELSE
    for i=0, nScans-1 DO begin
      thisOpd = opd[*, i]
      thisSig = sig[*, i]
      ;    zpd = 0.0
      ;    minDif = MIN(ABS(thisOpd), whZPD)
      ;    whZpd = WHERE(thisOpd EQ 0.0, whCount)
      zoomplot, dat.opd, avgSig, title = Sample + ' ' + rt + ' ' + det + ' ' + res + ' Scan ' + STRTRIM(i, 2)
      minDif = MIN(ABS(dat.opd-zpd_app), whZPD)
      thisShiftSig = SHIFT(thisSig, -whZPD)
      pad1 = thisShiftSig[0:N_ELEMENTS(thisShiftSig)/2.]
      pad2 = DBLARR(N_ELEMENTS(thisShiftSig)*15L)
      pad3 = thisShiftSig[N_ELEMENTS(thisShiftSig)/2.+1:N_ELEMENTS(thisShiftSig)-1]
      thisShiftSigPad = [pad1, pad2, pad3]

      print, N_ELEMENTS(thisShiftSig), N_ELEMENTS(thisShiftSigPad)
      totalSpec = DBLARR(N_ELEMENTS(thisShiftSig)/2. + 1)
      ;nPoints = N_ELEMENTS(thisShiftSig)/2. + 1

      thisWn = DINDGEN(nPoints)*ds
      thisSpec = (FFT(thisShiftSig, -1))[0:nPoints-1]*nPoints
      thisWnPad = DINDGEN(nPointsPad)*ds/16L
      thisSpecPad = (FFT(thisShiftSigPad, -1))[0:nPointsPad-1]*nPointsPad
      thisPhase  = ATAN(IMAGINARY(thisSpec)/REAL_PART(thisSpec))
      wh = WHERE(thisWN GE MIN(whRange) AND thisWn LE MAX(whRange))
      pFit = POLY_FIT(thisWn[wh], thisWn[wh], order, MEASURE_ERRORS = 1./ABS(thisPhase[wh])^2, yFit = theFit)
      zoomplot, thisSpec, spec, obj_ref = sObj, xr = xr
      sObj->add, thisWn, IMAGINARY(thisSpec), color = 'red', thick=3

      zoomplot, thisWn, avgPhase, obj_ref = pObj, xr = xr
      pObj->add, thisWn[wh], theFit, color = 'red', thick=3

      thisFit = pFit[0] + thisWn*pFit[1]
      theFullPhase = EXP(DCOMPLEX(DBLARR(N_ELEMENTS(thisWn)), -(thisFit)))
      pcSpec = thisSpec*theFullPhase

      zoomplot, thisWn, pcFact*thisSpec, xr = xr, obj_ref = pObj, title = 'Scan ' + STRTRIM(i, 2)
      pObj->add, thisWnPad, pcFact*thisSpecPad, color = 'blue'
      pObj->add, thisWn, pcFact*pcSpec, color = 'green'
      pcSpecs = pcSpecs+REAL_PART(pcSpec)
      theseSpecs = theseSpecs+REAL_PART(thisSpec)
      theseSpecsPad = theseSpecsPad+REAL_PART(thisSpecPad)
      ;STOP
    endfor

    titleStr = sample + ' ' + det + ' Resolution='+resStr+' cm$^{-1}$'

    outDataFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
 
    p = plot(thisWn, pcFact*theseSpecs/nScans, $
      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = xr, yrange=[-5e3, 3.e4])
    pFile = outDataFileRoot + '.jpg'
    p = plot(thisWnPad, pcFact*theseSpecsPad/nScans, color = 'blue', /overp)
    p.save, outDataDir+'\'+pFile
    p.save, resultsDir+'\'+pFile

    outFile = outDataFileRoot + '_processed.spc'
    WRITE_SPC,outDataDir+'\'+outFile,pcFact*theseSpecs/nScans,thisWn[0],thisWn[1]-thisWn[0]
    WRITE_SPC,resultsDir+'\'+outFile,pcFact*theseSpecs/nScans,thisWn[0],thisWn[1]-thisWn[0]
    outFile = outDataFileRoot + '_pad_processed.spc'
    WRITE_SPC,outDataDir+'\'+outFile,pcFact*theseSpecsPad/nScans,thisWnPad[0],thisWnPad[1]-thisWnPad[0]
    WRITE_SPC,resultsDir+'\'+outFile,pcFact*theseSpecsPad/nScans,thisWnPad[0],thisWnPad[1]-thisWnPad[0]
    STOP
  endforeach
  ;  
END