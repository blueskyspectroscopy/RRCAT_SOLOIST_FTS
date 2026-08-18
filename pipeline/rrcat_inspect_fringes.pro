PRO rrcat_inspect_fringes

  nHDPE = 1.54   ; refractive index of film material
  nPS = 1.58   ; refractive index of film material
  DHDPE = 1.58e-1 ; HDPE thickness is 1.58 mm
  DPS = 1.58e-1 ; PS thickness is 1.58 mm
  wn = findgen(101)*10

  RHDPE = (nHDPE - 1.)^2 / (nHDPE + 1.)^2   ; reflection
  RPS = (nPS - 1.)^2 / (nPS + 1.)^2     ; reflection


  ;  rootDir = 'V:\RRCAT\Data\2018_05_29\'
  rootDir = 'V:\RRCAT\Data\2018_05_28\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  resultsDir = rootDir + 'results\'
  ;  sampleDir = 'HDPE_reflection_tes_standard_res'
  ;  refDir = 'Gold_reflection_tes_standard_res'

  rts = ['Reflection']
  samples = ['HDPE', 'Polystyrene']
  dets = ['TES', 'HEB']
  ress = ['Standard']
  ;  rt = 'Reflection'
  ;  ;rt = 'Transmission'
  ;  ;  sample='Polystyrene'
  ;  sample='HDPE'
  ;  det='MCT'
  ;res = 'Standard'

  foreach rt, rts do begin
    
    foreach sample, samples do begin
      foreach det, dets do begin
        foreach res, ress do begin

          IF rt EQ 'Reflection' GT 0 THEN BEGIN
            rtStr = 'refl'
          ENDIF
          IF rt EQ 'Transmission' GT 0 THEN BEGIN
            rtStr = 'trans'
          ENDIF

          IF res EQ 'High' GT 0 THEN BEGIN
            resStr = '0.055'
          ENDIF ELSE BEGIN
            resStr = '0.2'
          ENDELSE

          IF rt EQ 'Reflection' then ref = 'Gold' ELSE ref = 'Reference'
          sampleDir = processedRoot + det + '\' + rt + '\' + sample + '\' + res + '_res\'
          sampleFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
          read_spc, sampleDir+sampleFileRoot+'_ratio.spc', sampleWn, sampleSpec
          sampleFileAbs = sampleFileRoot + '_ratio_abs.spc'
          read_spc, sampleDir+sampleFileAbs, sampleWn, sampleSpecAbs

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
          HDPE = 8.* (1. - RHDPE)^2 * RHDPE * cos(2. * !pi * (sampleWn * DHDPE * sqrt(nHDPE^2 - .5) + .25))^2
          PS = 8.* (1. - RPS)^2 * RPS * cos(2. * !pi * (sampleWn * DHDPE * sqrt(nPS^2 - .5) + .25))^2

          IF sample EQ 'HDPE' THEN theFringe = HDPE
          IF sample EQ 'Polystyrene' THEN theFringe = PS
     
          ;STOP
          titleStr = sample + ' ' + rt + ' ' + det + ' ' + res + ' Resolution'


          result = FILE_INFO(resultsDir)
          IF result.exists EQ 0 THEN FILE_MKDIR, resultsDir
          scale = 1.0
          offset=0.0
          p = plot(sampleWn, sampleSpec, xrange = xr, yrange = yr, thick = 2,$
            xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Sample/Reference', title = titleStr)
          pfile = sampleFileRoot + '_ratio.jpg'

          p = plot(wn, theFringe*scale+offset, color = 'red', thick=2, /overplot)
          p = plot(sampleWn, sampleSpecAbs, xrange = xr, yrange = yr, thick = 2,$
            xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Sample/Reference', title = titleStr)
          pfile = sampleFileRoot + '_ratio_abs.jpg'
          p = plot(wn, theFringe*scale+offset, color = 'red', thick=2, /overplot)
          
          STOP
          
        endforeach
      endforeach
    endforeach
  endforeach
END