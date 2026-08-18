PRO rrcat_inspect_resolution

  rootDir = 'V:\RRCAT\Data\'
  ;  sampleDir = 'HDPE_reflection_tes_standard_res'
  ;  refDir = 'Gold_reflection_tes_standard_res'


  ;
  btramDir =  rootDir+'BTRAM\
  read_spc, btramDir+'BTRAM 0-750 transmission.spc', bWn, btram
  airDir = rootDir + '2018_05_28\results\Transmission\'
  vacDir = rootDir + '2018_05_30\results\Transmission\'
  refFile = 'Reference_trans_TES_0.055res_processed_abs.spc'
  read_spc, airDir+refFile, airWn, airSpec
  read_spc, vacDir+refFile, vacWn, vacSpec
  trans = airSpec/vacSpec
  zoomplot, airWn-0.055, trans, obj_ref=pObj, yrange = [-.1, 1], xr = [0, 800]
  pObj->add, bWn, btram, color = 'green'
  stop
  
  p = plot(airWn-0.055, trans, yrange = [-.1, 1], xr = [0, 800], $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Transmission' )
  p = plot(bWn, btram, color = 'green', /over)

  p = plot(airWn-0.055, trans, yrange = [0.5, 1], xr = [514.15, 514.45], $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Transmission' )
  p = plot(bWn, btram, color = 'green', /over)
  stop
END