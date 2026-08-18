PRO rrcat_compute_reflection_transmission_06_03

  ;rootDir = 'U:\RRCAT\Data\2018_06_01\'
  rootDir = 'U:\RRCAT\Data\verification_tests\all_vacuum_results\'
  ;rootDir = 'V:\RRCAT\Data\2018_05_31\'
  ;rootDir = 'V:\RRCAT\Data\2018_05_30\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  ;  sampleDir = 'HDPE_reflection_tes_standard_res'
  ;  refDir = 'Gold_reflection_tes_standard_res'

  rts = ['Reflection', 'Transmission']
  ;rts = ['Reflection']
  samples = ['HDPE', 'Polystyrene']
  ;samples = ['Polystyrene']
  dets = ['TES', 'MCT', 'Pyro']
  ;dets = ['MCT']
  ress = ['Standard'];, 'High']

  res = 'Standard'

  foreach det, dets do begin
    foreach rt, rts do begin
      foreach sample, samples do begin

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

        IF rt EQ 'Reflection' then begin
          ref = 'Gold'
          ytitle = 'Reflectance (a. u.)'
        ENDIF ELSE BEGIN
          ref = 'Reference'
          ytitle = 'Transmission'
        ENDELSE


        sampleFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
        refFileRoot = ref + '_' + rtStr + '_' + det + '_' + resStr + 'res'
        ;read_spc, rootDir+sampleFileRoot+'_processed.spc', sampleWn, sampleSpec
        ;read_spc, rootDir+refFileRoot+'_processed.spc', refWn, refSpec
        sampleFileAbs = sampleFileRoot + '_processed_abs.spc'
        refFileAbs = refFileRoot + '_processed_abs.spc'
        read_spc, rootDir+rt+'\'+sampleFileAbs, sampleWn, sampleSpecAbs
        read_spc, rootDir+rt+'\'+refFileAbs, refWn, refSpecAbs

        IF det EQ 'TES' THEN BEGIN
          xr = [0, 800]
        ENDIF
        IF det EQ 'HEB' THEN BEGIN
          xr = [0, 100]
        ENDIF

        IF det EQ 'MCT' THEN BEGIN
          xr = [0, 2500]
        ENDIF
        IF det EQ 'Pyro' THEN BEGIN
          ;  xr = [0, 700]
          xr = [0, 2500]
        ENDIF
        yr = [-0.2, 1.2]
        ;        zoomplot, sampleWn, sampleSpec, obj_ref=pObj, xrange = xr
        ;        pObj->add, refWn, refSpec, color = 'red'

        ;        reflection = sampleSpec/refSpec
        zoomplot, refWn, sampleSpecAbs/refSpecAbs, xrange = xr, yrange= yr, obj_ref=rObj
        ;        rObj->add, sampleWn, reflection, color = 'green'
        ;STOP
        titleStr = sample + ' ' + det + ' Resolution='+resStr+' cm$^{-1}$'
        resultsDir = rootDir
        result = FILE_INFO(resultsDir)
        IF result.exists EQ 0 THEN FILE_MKDIR, resultsDir

        ;        p = plot(sampleWn, reflection, xrange = xr, yrange = yr,$
        ;          xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = ytitle, title = titleStr)
        ;        pfile = sampleFileRoot + '_ratio.jpg'
        ;        p.save, outDataDir+'\'+pfile

        p = plot(sampleWn, sampleSpecAbs/refSpecAbs, xrange = xr, yrange = yr,$
          xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = ytitle)
        pfile = sampleFileRoot + '_ratio_abs.jpg'
        ;        p.save, outDataDir+'\'+pfile
        ;p.save, resultsDir+rt+'\'+pfile
        ; p.close
        ;        outFile = sampleFileRoot + '_ratio.spc'
        ;        ;  p.close
        ;        WRITE_SPC,outDataDir+'\'+outFile,reflection,sampleWn[0],sampleWn[1]-sampleWn[0]

        outFile = sampleFileRoot + '_ratio_abs.spc'
        ;STOP
        ;        WRITE_SPC,outDataDir+outFile,sampleSpecAbs/refSpecAbs,sampleWn[0],sampleWn[1]-sampleWn[0]
        ;WRITE_SPC,resultsDir+rt+'\'+outFile,sampleSpecAbs/refSpecAbs,sampleWn[0],sampleWn[1]-sampleWn[0]
        ; S;TOP
      endforeach
    endforeach
  endforeach
END