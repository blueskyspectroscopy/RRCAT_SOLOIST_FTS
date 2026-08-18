PRO rrcat_plot_btram_data

  btramDir =  'V:\RRCAT\Data\BTRAM\

  rootDir = 'V:\RRCAT\Data\2018_05_29\'
  ;rootDir = 'V:\RRCAT\Data\2018_05_28\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  resultsDir = rootDir + 'results\'
  ;  sampleDir = 'HDPE_reflection_tes_standard_res'
  ;  refDir = 'Gold_reflection_tes_standard_res'

  rts = ['Reflection']
  samples = ['HDPE', 'Polystyrene']
  dets = ['TES', 'HEB']
  dets = ['MCT']
  ress = ['Standard']
  res = 'Standard'
  ;  rt = 'Reflection'
  ;  ;rt = 'Transmission'
  ;  ;  sample='Polystyrene'
  ;  sample='HDPE'
  ;  det='MCT'
  res = 'Standard'

  foreach rt, rts do begin

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

        refDir = processedRoot + det + '\' + rt + '\' + ref + '\' + res + '_res\'
        refFileRoot = ref + '_' + rtStr + '_' + det + '_' + resStr + 'res'
        read_spc, refDir+refFileRoot+'_processed.spc', sampleWn, sampleSpec
        read_spc, refDir+refFileRoot+'_processed_abs.spc', sampleWn, sampleSpecAbs

        read_spc, btramDir+'BTRAM 0-750 transmission.spc', bWn0, btram0
        read_spc, btramDir+'BTRAM 500-2500 emission.spc', bWn1, btram1


        yr = [-0.1, 1.1]

        ;STOP
      titleStr = ref + ' ' + det + ' Resolution='+resStr+' cm$^{-1}$'


        IF ref EQ 'Gold' AND det EQ 'TES' then yr = [-1.0, 11]
        IF ref EQ 'Gold' AND det EQ 'HEB' then yr = [-5, 100]
        IF ref EQ 'Reference' AND det EQ 'TES' then yr = [-0.5, 20]
        IF ref EQ 'Reference' AND det EQ 'HEB' then yr = [-5, 200]
        IF ref EQ 'Gold' AND det EQ 'MCT' then yr = [-0.5, 6]
        IF ref EQ 'Gold' AND det EQ 'Pyro' then yr = [-.5, 5]
        IF ref EQ 'Reference' AND det EQ 'MCT' then yr = [-0.5, 20]
        IF ref EQ 'Reference' AND det EQ 'Pyro' then yr =  [-.5, 5]
        bscale=1.
        IF det EQ 'TES' then begin
          xr = [0, 800]
          bWn = bWn0
          btram = btram0
        ENDIF
        IF det EQ 'HEB' then begin
          xr = [0, 100]
          bWn = bWn0
          btram = btram0
        ENDIF
        IF det EQ 'MCT' then begin
          xr = [0, 2500]
          bWn = bWn1
          btram = btram1
                  bscale=0.1
        ENDIF
        IF det EQ 'Pyro' then begin
          xr = [0, 2500]
          bWn = bWn0
          btram = btram0
          
        ENDIF
        result = FILE_INFO(resultsDir)
        IF result.exists EQ 0 THEN FILE_MKDIR, resultsDir
        scale = bscale*MAX(yr)

        ;IF det EQ 'MCT' then bscale=3.
        offset = 0.0
;        p = plot(sampleWn, sampleSpec, xrange = xr, yrange = yr, thick = 2,$
;          xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)', title = titleStr)
;        pfile = refFileRoot + '_btram.jpg'
;
;        p = plot(bWn, btram*scale+offset, color = 'green', /overplot)
;        p = plot(sampleWn, sampleSpec, /overplot)
        p = plot(sampleWn, sampleSpecAbs, xrange = xr, yrange = yr, thick = 2,$
          xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)');, title = titleStr)
        
        p = plot(bWn, btram*scale+offset, color = 'green', /overplot)
        p = plot(sampleWn, sampleSpecAbs, /overplot)
        
        STOP

      endforeach
    endforeach
  endforeach
END