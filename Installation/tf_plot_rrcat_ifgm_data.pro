pro tf_plot_rrcat_ifgm_data
  ;read_spc, f, wn, spec
  ;p=plot(wn, spec, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (arb.)', xstyle=1, ystyle=1, thick=2)

  ; Reflection
  dataDir = 'R:\data_archive\RRCAT\Installation\2018_09_10\'
  dataFile = 'Sample_Reflection_MCT_GM_180910_1432_avg_50.ifg'
  rrcat_dat = RRCAT_SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  p=plot(rrcat_dat.opd, (rrcat_dat.signal-MEDIAN(rrcat_dat.signal))*200./5., title = 'Reflection (RRCAT)', $
    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)

  dataDir = 'R:\data_archive\RRCAT\Data\2018_05_29\MCT\Gold_Mirror\'
  dataFile = 'MCT_refl_180529_0051_avg_50.ifg'
  bs_dat = SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  p=plot(bs_dat.opd, bs_dat.signal, title = 'Reflection (Blue Sky)', $
    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)

  STOP

  ; Transmission
  dataDir = 'R:\data_archive\RRCAT\Installation\2018_09_10\'
  dataFile = 'Reference_Transmission_MCT_GM_180910_1353_avg_20.ifg'
  rrcat_dat = RRCAT_SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  p=plot(rrcat_dat.opd, (rrcat_dat.signal-MEDIAN(rrcat_dat.signal))*200/5., title = 'Transmission (RRCAT)', $
    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)


  dataDir = 'R:\data_archive\RRCAT\Data\2018_06_01\MCT_reference_trans_standard_res\'
  dataFile = 'MCT_REF_180601_0151_avg_50.ifg'
  bs_dat = SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  p=plot(bs_dat.opd, bs_dat.signal, title = 'Transmission (Blue Sky)', $
    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)

  STOP
end