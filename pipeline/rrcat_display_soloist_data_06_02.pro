PRO rrcat_display_soloist_data_06_02, RRCAT=RRCAT
  dateStr = '2018_05_31'
  rootDir = 'U:\RRCAT\Data\' + dateStr + '\'
  processedRoot = rootDir + 'processed\'

  dataDirRoot = rootDir
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  pcFact = 1.

  dataDirs = [ $
;        'HEB_HDPE_trans_standard_res', $
;        'HEB_PS_trans_standard_res', $
;        'Pyro_reference_trans_standard_res', $
        'Pyro_HDPE_trans_standard_res', $
        'Pyro_PS_trans_standard_res'];, $
    ;    'HEB_reference_trans_standard_res', $
    ; 'HEB_ref_trans_hi_res'];, $
    ;      'TES_ref_trans_standard_res', $
    ;       'TES_reference_trans_hi_res', $
    ;             'TES_PS_trans_standard_res'];, $
    ;    'TES_PS_trans_standard_res', $

;    'HEB_reference_trans_standard_res', $
;      'TES_Gold_refl_standard_res', $
;;;;;      'Pyro_Gold_refl_standard_res', $
;      'TES_HDPE_refl_standard_res', $
;      'Pyro_HDPE_refl_standard_res', $
    ;  'TES_null_refl_standard_res']
    ;    'Pyro_null_refl_standard_res', $
;        'TES_PS_refl_standard_res', $
;        'Pyro_PS_refl_standard_res']
;        'MCT_Gold_refl_standard_res', $
    ;    'MCT_null_refl_standard_res', $
;        'MCT_HDPE_refl_standard_res', $
;        'MCT_PS_refl_standard_res', $
;        'HEB_Gold_refl_standard_res', $
  ;  'HEB_null_refl_standard_res', $
;      'HEB_HDPE_refl_standard_res'];, $
;      'HEB_PS_refl_standard_res'

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


    firstTime = 1
    dataFiles = FILE_SEARCH(dataDirRoot+ dataDir+'\', '*avg*.spc')
    IF N_ELEMENTS(dataFiles) NE 1 OR dataFiles EQ '' THEN STOP
    read_spc, dataFiles[0], aWn, aSpec
    nPoints = N_ELEMENTS(aSpec)
    ;
    ; observation specific parameters
    ;
    IF det EQ 'TES' THEN BEGIN
      xr = [0, 800]
      ymin = -0.5
      yMax = 80
      IF sample EQ 'Gold' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin=475
        wnMax=600
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0003
        wnMin = 425
        wnMax = 560
        yMax = 5
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 425
        wnMax = 560
        yMax = 5
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
        yMax = 250
      ENDIF
      IF sample EQ 'Gold' AND res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin= 20
        wnMax = 60
        yMax = 1000
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
        yMax = 300
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.00016
        wnMin= 20
        wnMax = 60
        yMax = 300
        pcFact = -1.0
      ENDIF
      IF sample EQ 'null' and res EQ 'Standard' then begin
        zpd_app = -0.00016
        wnMin= 20
        wnMax = 60
        yMax = 100
        pcFact = -1.0
      ENDIF
    ENDIF

    IF det EQ 'MCT' THEN BEGIN
      xr = [0, 2500]
      ymin = -0.5
      IF sample EQ 'Reference' AND res EQ 'Standard' then begin
        zpd_app = -0.0026
        wnMin = 1000
        wnMax = 1400
        yMax = 60
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
        yMax = 15
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0026
        wnMin = 1000
        wnMax = 1400
        yMax = 15
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Gold' AND res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 60
        pcFact = -1.0
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 15
        pcFact = -1.0
      ENDIF
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0666
        wnMin = 1000
        wnMax = 1400
        yMax = 15
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
      ymin = -0.5
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
      IF sample EQ 'HDPE' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 20
      ENDIF
      IF sample EQ 'Polystyrene' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 20
      ENDIF
      IF sample EQ 'null' and res EQ 'Standard' then begin
        zpd_app = -0.0002
        wnMin = 300
        wnMax = 600
        pcFact = -1.0
        yMax = 1.5
      ENDIF
    ENDIF
    zoomplot, aWn, aSpec*npoints, xrange = xr, yrange=[ymin, yMax]
    outDataFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
    print, outDataFileRoot
    STOP
    nPoints = N_ELEMENTS(aSpec)
    p=plot(aWn, aSpec*npoints, $
      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)', xrange = xr, yrange=[ymin, yMax])
    pFile = outDataFileRoot + '_abs.jpg'
    p.save, outDataDir+'\'+pFile
    p.save, resultsDir+'\'+pFile
    outFile = outDataFileRoot + '_processed.spc'

    outFile = outDataFileRoot + '_processed_abs.spc'
    WRITE_SPC,outDataDir+'\'+outFile,aSpec,aWn[0],aWn[1]-aWn[0]
    WRITE_SPC,resultsDir+'\'+outFile,aSpec,aWn[0],aWn[1]-aWn[0]
  endforeach

  STOP
END