PRO tf_rrcat_fit_line_display
;  mainDir = 'U:\RRCAT\Data\2018_05_31\results\Transmission\'
;  dataFiles = ["VDI_trans_Pyro_0.055res_processed.spc", "VDI_trans_TES_0.055res_processed.spc"]
;  dataFilesPad = ["VDI_trans_Pyro_0.055res_pad_processed.spc", "VDI_trans_TES_0.055res_pad_processed.spc"]
;  lineAmps = [2.5e4, 3e4]
       mainDir = 'U:\RRCAT\Data\2018_06_01\results\Transmission\'
       dataFiles = ["VDI_trans_HEB_0.055res_processed.spc"]
       dataFilesPad = ["VDI_trans_HEB_0.055res_pad_processed.spc"]
       lineAmps = [15.e4]

  foreach inFile, dataFiles, fIndex do begin
    ;IF STRPOS(inFile, 'TES') GE 0 THEN det = 'TES' ELSE det = 'Pyro'
    det = 'HEB'
    padFile = dataFilesPad[fIndex]
    read_spc, mainDir+inFile, wn, spec, error=err
    read_spc, mainDir+padFile, wnPad, specPad, error=err
    wh = WHERE(wn GE 9.5 AND wn LE 12.5)
    whPad = WHERE(wnPad GE 9.5 AND wnPad LE 12.5)
    parinfo = REPLICATE({value:0.D, fixed:0, limited:[0,0], limits:[0.,0.]}, 4)

    parinfo(3).value = 0
    parinfo(3).fixed = 1

    parinfo(0).value = lineAmps[fIndex]
    parinfo(0).fixed = 0

    parinfo(1).value = 11.0
    parinfo(1).limited = [1, 1]
    parinfo(1).limits = [10.95, 11.05]
    dWn = 0.055
    parinfo(2).value = 1/dWn
    parinfo(2).fixed = 0
    parinfo(2).limited = 0
    parinfo(2).limits = [0.05, 0.06]

    result = mpfitfun('TF_SPICA_fit_line', (wn[wh]), spec[wh], $
      measure_errors, yfit = yfit, maxiter = maxiter, $
      /quiet, perror = perror, niter = niter, status = stat, $
      parinfo=parinfo)
    print, "Continuum: " + STRTRIM(result[3], 2) +", +/- " + STRTRIM(perror[0], 2)  $
      + ", Amplitude: "    + STRTRIM(result[0], 2) +", +/- " + STRTRIM(perror[1], 2)  $
      + ", Centre: "       + STRTRIM(result[1], 2) +", +/- " + STRTRIM(perror[2], 2) $
      + ", Resolution: "   + STRTRIM(1/result[2], 2) +", +/- " + STRTRIM(perror[3], 2)
    p = plot(wn[wh], spec[wh]/100., thick=2, xr = [10.4, 11.6], $
      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)')
    p = plot(wn[wh], yfit, color = 'green', /overplot)
    oversampledwn = DINDGEN(N_ELEMENTS(wh)*100L)*(0.055/100.)+MIN(wn[wh])
    oversampledSinc = TF_SPICA_fit_line(oversampledwn, result)
    p = plot(oversampledwn, oversampledSinc, color = 'green', /overplot)
    pFile = "vdi_fit_"+det+".jpg"
    ;p.save, mainDir+pFile

    p = plot(wnPad[whPad], specPad[whPad]/100., thick=2, xr = [10.4, 11.6], $
      xtitle = 'Wavenumber cm$^{-1}$', ytitle = 'Signal (a.u.)')
    result[2] = 22.
    oversampledSinc = TF_SPICA_fit_line(wnPad[whPad], result)
    p = plot(wnPad[whPad], oversampledSinc/100., color = 'green', /overplot, thick=2)
    ;p = plot(oversampledwn, oversampledSinc, color = 'green', /overplot)
    pFile = "vdi_fit_"+det+"_fitted_pad.jpg"
    ;p.save, mainDir+pFile
    stop
  endforeach
  STOP
END