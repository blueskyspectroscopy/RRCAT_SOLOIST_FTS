PRO rrcat_compute_reflection_transmission_inspect_fringes

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
  rts = ['Transmission']
  samples = ['HDPE', 'Polystyrene']
  ;samples = ['Polystyrene']

  ;dets = ['MCT']
  ress = ['Standard'];, 'High']

  res = 'Standard'

  foreach rt, rts do begin
    foreach sample, samples do begin

      IF rt EQ 'Reflection' GT 0 THEN BEGIN
        rtStr = 'refl'
      ENDIF
      IF rt EQ 'Transmission' GT 0 THEN BEGIN
        rtStr = 'trans'
      ENDIF
      resStr = '0.2'

      IF rt EQ 'Reflection' then begin
        ref = 'Gold'
        ytitle = 'Reflectance (a. u.)'
      ENDIF ELSE BEGIN
        ref = 'Reference'
        ytitle = 'Transmission'
      ENDELSE

      det='TES'
      tesFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
      det='HEB'
      hebFileRoot = sample + '_' + rtStr + '_' + det + '_' + resStr + 'res'
      det='TES'
      reftesFileRoot = ref + '_' + rtStr + '_' + det + '_' + resStr + 'res'
      det='HEB'
      refhebFileRoot = ref + '_' + rtStr + '_' + det + '_' + resStr + 'res'
      ;read_spc, rootDir+sampleFileRoot+'_processed.spc', sampleWn, sampleSpec
      ;read_spc, rootDir+refFileRoot+'_processed.spc', refWn, refSpec
      sampleFileAbsTes = tesFileRoot + '_processed_abs.spc'
      refFileAbsTes = reftesFileRoot + '_processed_abs.spc'
      sampleFileAbsHeb = hebFileRoot + '_processed_abs.spc'
      refFileAbsHeb = refhebFileRoot + '_processed_abs.spc'
      read_spc, rootDir+rt+'\'+sampleFileAbstes, sampleWntes, sampleSpecAbstes
      read_spc, rootDir+rt+'\'+refFileAbstes, refWntes, refSpecAbstes
      read_spc, rootDir+rt+'\'+sampleFileAbsheb, sampleWnheb, sampleSpecAbsheb
      read_spc, rootDir+rt+'\'+refFileAbsheb, refWnheb, refSpecAbsheb

      xr = [0, 100]


      yr = [-0.2, 0.3]
      ;        zoomplot, sampleWn, sampleSpec, obj_ref=pObj, xrange = xr
      ;        pObj->add, refWn, refSpec, color = 'red'

      ;        reflection = sampleSpec/refSpec
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

      p = plot(sampleWntes, sampleSpecAbstes/refSpecAbstes, xrange = xr, yrange = yr,$
        xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = ytitle)
      If rt EQ 'Transmission' then rFact = 2. else rFact = 1.

      p = plot(sampleWnheb, sampleSpecAbsheb/refSpecAbsheb*rfact, color='blue', /overp)

      stop
    endforeach
  endforeach

END