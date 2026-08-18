PRO rrcat_inspect_fringes_06_04



  ;  rootDir = 'V:\RRCAT\Data\2018_05_29\'
  rootDirRef = 'U:\RRCAT\Data\2018_05_30\'
  rootDir = 'U:\RRCAT\Data\2018_05_31\'
  processedRoot = rootDir + 'processed\'
  res = FILE_INFO(processedRoot)
  IF res.exists EQ 0 THEN FILE_MKDIR, processedRoot
  resultsDir = rootDir + 'results\Transmission\'
  resultsDirRef = rootDirRef + 'results\Transmission\'
  ;
  refFile = 'Reference_trans_HEB_0.2res_processed_abs.spc'
  hdpeFile = 'HDPE_trans_HEB_0.2res_processed_abs.spc'
  psFile = 'Polystyrene_trans_HEB_0.2res_processed_abs.spc'

  read_spc, resultsDirRef+refFile, refWn, refSpec
  read_spc, resultsDir+hdpeFile, hdpeWn, hdpeSpec
  read_spc, resultsDir+psFile, psWn, psSpec
  p = plot(refWn, refSpec, xrange = [0, 100], yrange = [-.5, 100], thick = 2,$
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)')
  p = plot(hdpeWn, hdpeSpec*60/25., thick=2, color = 'blue', /overp)
  p = plot(psWn, psSpec*60/20., thick=2, color = 'red', /overp)
  STOP

END