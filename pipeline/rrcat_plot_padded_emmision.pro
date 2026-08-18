PRO rrcat_plot_padded_emmision

  read_spc, 'V:\RRCAT\Data\2018_05_30\results\Transmission\Reference_trans_TES_0.055res_processed_abs.spc', wn, spec
  read_spc, DIALOG_PICKFILE(), bwn, bspec
  dat = soloist_fts_read_file('V:\RRCAT\Data\2018_05_28\Reference_transmission_tes_hi_res\Reference_180528_1201_avg_50.ifg')
  ifgm = FFT(spec)
  print, n_ELEMENTS(ifgm)

  p=plot(newWn, newSpec/42., xr = [417, 420], yr = [0.91, 0.98], $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)')
  p=plot(bwn, bspec*0.04/0.8+0.91, color='green', /over)
  p=plot(newWn+0.055/2, newSpec/42., xr = [417, 420], yr = [0.91, 0.98], $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)')
  p=plot(bwn, bspec*0.04/0.8+0.91, color='green', /over)

END