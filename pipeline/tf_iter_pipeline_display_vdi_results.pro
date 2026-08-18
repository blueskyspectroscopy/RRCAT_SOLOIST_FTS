PRO tf_iter_pipeline_display_vdi_results
  mainDir = "R:\data_archive\Data\2016_12_13_tests\processed\"
  fNamePad = "laserSpectra_ch0_zero_pad_1.spc"
  fName = "laserSpectra_ch0_no_pad_1.spc"
  IfgmFName = "meanIfgm_ch0_1.spc"

  dirList = [ $
    "acceptance_tests_frequency_320GHz", $
    "acceptance_tests_frequency_321GHz", $
    "acceptance_tests_frequency_322GHz", $
    "acceptance_tests_frequency_323GHz", $
    "acceptance_tests_frequency_324GHz", $
    "acceptance_tests_frequency_325GHz", $
    "acceptance_tests_frequency_326GHz", $
    "acceptance_tests_frequency_327GHz", $
    "acceptance_tests_frequency_328GHz", $
    "acceptance_tests_frequency_329GHz", $
    "acceptance_tests_frequency_330GHz" $
    ]

  dirList = [ $
    "acceptance_tests_frequency_320GHz" $
    ]
  xrange = [100, 600]
  for iDir =0, N_ELEMENTS(dirList)-1 do begin
    thisDir = dirList[iDir]
    dataDir = mainDir + thisDir +'\'
    read_spc, dataDir+fNamePad, freqPad, specPad, error=err
    read_spc, dataDir+fName, freq, spec, error=err
    read_spc, dataDir+IfgmFName, opd, meanIfgm, error=err
    wh0 = WHERE(meanIfgm EQ 0, whCount)
    minOpd = opd[whCount]
    maxOpd = MAX(opd)
    print, opd[whCount], MAX(opd)
    p = Plot(/test, /nodata, $
      Title = "Frequency Tests "+STRMID(thisDir, 5, /REVERSE), $
      xtitle = "Frequency (GHz)", $
      ytitle = "Normalized Signal", $
      xrange = xrange, $
      yRange = [-0.5, 1.1], $
      ystyle = 1)
    p = plot(freqPad*!C_/1e7, -specPad/MAX(-specPad), color = 'black', /overplot)
    p = plot(freq*!C_/1e7, -spec/MAX(-specPad), color = 'red', /overplot)
    wh = WHERE(freqPad*!C_/1e7 GT xrange[0] and freqPad*!C_/1e7 LT xrange[1])
    parinfo = REPLICATE({value:0.D, fixed:0, limited:[0,0], limits:[0.,0.]}, 4)

    parinfo(0).value = 0
    parinfo(0).fixed = 1

    parinfo(1).value = 1
    parinfo(1).fixed = 1

    parinfo(2).value = FIX(STRMID(thisDir, 5, 3, /REVERSE))/(!C_/1e7)
    parinfo(2).limited = [1, 1]
    parinfo(2).limits = [310, 340]/(!C_/1e7)
    dWn = 1./(maxOpd-MinOpd)
    parinfo(3).value = 1/dWn
    parinfo(3).fixed = 1
    parinfo(3).limited = [1, 1]
    parinfo(3).limits = [2.5, 3.5]

    result = mpfitfun('TF_SPICA_fit_line', (freqPad[wh]), -specPad[wh], $
      measure_errors, yfit = yfit, maxiter = maxiter, $
      /quiet, perror = perror, niter = niter, status = stat, $
      parinfo=parinfo)
    print, "Continuum: " + STRTRIM(result[0], 2) $
      + ", Amplitude: "    + STRTRIM(result[1], 2) $
      + ", Centre: "       + STRTRIM(result[2]*!C_/1e7, 2)  + ", +/- " + STRTRIM(perror[2]*!C_/1e7, 2) $
      + ", Resolution: "   + STRTRIM(1/result[3]*!C_/1e7, 2)
    p = plot(freqPad[wh]*!C_/1e7, yfit, color = 'green', /overplot)
    pFile = "laser_pad_and_fit_"+STRMID(thisDir, 5, /REVERSE)+".jpg"
    p.save, mainDir+pFile
    ;stop
  endfor
  STOP
END