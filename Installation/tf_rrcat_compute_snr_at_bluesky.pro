pro tf_rrcat_compute_SNR_at_blueSky
  ;read_spc, f, wn, spec
  ;p=plot(wn, spec, xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (arb.)', xstyle=1, ystyle=1, thick=2)

  ; Reflection
  rootDir = 'R:\data_archive\RRCAT\Data\'

  ;
  ; Vacuum
  ;
  dataFiles = [ $
    '2018_06_01\TES_null_refl_standard_res\TES_null_180602_0051_avg_50.ifg', $
    '2018_06_01\TES_Gold_refl_standard_res\TES_Gold_180601_0595_avg_50.ifg', $
    '2018_06_01\TES_HDPE_refl_standard_res\TES_hdpe_180601_0051_avg_50.ifg', $
    '2018_06_01\TES_PS_refl_standard_res\TES_PS_180602_0071_avg_50.ifg', $
    '2018_05_30\TES_reference_trans_standard_res\TES_vac_180530_0251_avg_150.ifg', $
    '2018_05_30\TES_HDPE_trans_standard_res\TES HDPE_180530_0101_avg_100.ifg', $
    '2018_05_30\TES_PS_trans_standard_res\TES_PS_180530_0101_avg_100.ifg', $
    '2018_06_02\HEB_null_refl_standard_res\HEB_null_180603_0201_avg_100.ifg', $
    '2018_06_02\HEB_Gold_refl_standard_res\HEB_Gold_180603_0101_avg_100.ifg', $
    '2018_06_02\HEB_HDPE_refl_standard_res\HEB_HDPE_180603_0101_avg_100.ifg', $
    '2018_06_02\HEB_PS_refl_standard_res\HEB_PS_180603_0101_avg_100.ifg', $
    '2018_05_30\HEB_reference_trans_standard_res\heb_vac_180530_0400_avg_100.ifg', $
    '2018_06_01\HEB_reference_trans_standard_res\HEB_REF_180601_0101_avg_100.ifg', $
    '2018_05_31\HEB_HDPE_trans_standard_res\HEB_HDPE_180531_0101_avg_100.ifg', $
    '2018_05_31\HEB_PS_trans_standard_res\HEB_PS_180531_0101_avg_100.ifg', $
    '2018_06_02\MCT_null_refl_standard_res\MCT_null_180602_0051_avg_50.ifg', $
    '2018_06_02\MCT_Gold_refl_standard_res\MCT_Gold_180602_0051_avg_50.ifg', $
    '2018_06_02\MCT_HDPE_refl_standard_res\MCT_HDPE_180602_0051_avg_50.ifg', $
    '2018_06_02\MCT_PS_refl_standard_res\MCT_PS_180602_0055_avg_50.ifg', $
    '2018_06_01\MCT_reference_trans_standard_res\MCT_REF_180601_0151_avg_50.ifg', $
    '2018_06_01\MCT_HDPE_trans_standard_res\MCT_HDPE_180601_0051_avg_50.ifg', $
    '2018_06_01\MCT_PS_trans_standard_res\MCT_PS_180601_0051_avg_50.ifg', $
    '2018_06_01\Pyro_null_refl_standard_res\Pyro_null_180602_0021_avg_20.ifg', $
    ;    '2018_06_01\Pyro_Gold_refl_standard_res\TES_Gold_180601_0595_avg_50.ifg', $
    '2018_06_01\Pyro_HDPE_refl_standard_res\pyro_hdpe_180601_0021_avg_20.ifg', $
    '2018_06_01\Pyro_PS_refl_standard_res\Pyro_PS_180602_0021_avg_20.ifg', $
    '2018_05_30\Pyro_reference_trans_standard_res\pyro_vac_180530_0021_avg_20.ifg', $
    '2018_05_31\Pyro_HDPE_trans_standard_res\Pyro_HDPE_180531_0021_avg_20.ifg', $
    '2018_05_31\Pyro_PS_trans_standard_res\Pyro_PS_180531_0021_avg_20.ifg' $
    ]

;  ;
;  ; Atmosphere
;  ;
;  dataFiles = [ $
;    '2018_05_28\Gold_reflection_tes_standard_res\Sample_Gold_180528_0350_avg_50.ifg', $
;    '2018_05_28\HDPE_reflection_tes_standard_res\Sample_HDPE_180528_0100_avg_50.ifg', $
;    '2018_05_28\PS_reflection_tes_standard_res\Sample_PS_180528_0250_avg_50.ifg', $
;    '2018_05_28\Gold_reflection_heb_standard_res\Sample_Gold_180528_0601_avg_50.ifg', $
;    '2018_05_28\HDPE_reflection_heb_standard_res\Sample_HDPE_180528_0401_avg_100.ifg', $
;    '2018_05_28\PS_reflection_heb_standard_res\Sample_PS_180528_0301_avg_50.ifg', $
;    '2018_05_29\MCT\Gold_Mirror\MCT_refl_180529_0051_avg_50.ifg', $
;    '2018_05_29\MCT\HDPE_refl\MCT_A_refl_180529_0051_avg_50.ifg', $
;    '2018_05_29\MCT\PS_refl\MCT_PS_refl_180529_0051_avg_50.ifg', $
;    '2018_05_29\Pyro\Gold_Mirror\pyro_mirr_180529_0063_avg_20.ifg', $
;    '2018_05_28\Reference_transmission_tes_standard_res\Reference_180528_1151_avg_50.ifg', $
;    '2018_05_28\HDPE_transmission_tes_standard_res\Sample_HDPE_180529_1301_avg_50.ifg', $
;    '2018_05_28\PS_transmission_tes_standard_res\Sample_PS_180529_1251_avg_50.ifg', $
;    '2018_05_28\Reference_transmission_heb_standard_res\Reference_180528_0801_avg_100.ifg', $
;    '2018_05_28\HDPE_transmission_heb_standard_res\Sample_HDPE_180528_0901_avg_100.ifg', $
;    '2018_05_28\PS_transmission_heb_standard_res\Sample_PS_180528_1001_avg_100.ifg', $
;    '2018_05_29\MCT\Ref_trans\MCT_trans_180529_0051_avg_50.ifg', $
;    '2018_05_29\MCT\HDPE_trans\MCT_HDPE_tr_180529_0051_avg_50.ifg', $
;    '2018_05_29\MCT\PS_trans\MCT_PS_tr_180529_0051_avg_50.ifg', $
;    '2018_05_29\Pyro\Ref_trans\pyro_ref_180529_0063_avg_62.ifg' $
;    ]
;
;
;  ;
;  ; Atmosphere, Hi-res
;  ;
;  dataFiles = [ $
;    '2018_05_28\Gold_reflection_tes_hi_res\Sample_Gold_180528_0400_avg_50.ifg', $
;    '2018_05_28\HDPE_reflection_tes_hi_res\Sample_HDPE_180528_0050_avg_50.ifg', $
;    '2018_05_28\Reference_transmission_tes_hi_res\Reference_180528_1201_avg_50.ifg', $
;    '2018_05_28\Gold_reflection_heb_hi_res\Sample_Gold_180528_0551_avg_50.ifg', $
;    '2018_05_28\Reference_transmission_heb_hi_res\Reference_180528_0701_avg_100.ifg', $
;    '2018_05_29\MCT\Ref_trans\MCT_trans_180529_0051_avg_50.ifg' $
;    ]
;
;
;  ;
;  ; Intermediate Port
;  ;
;  dataFiles = [ $
;    '2018_06_02\MCT_reference_intermediate_standard_res\MCT_ref_180602_0051_avg_50.ifg', $
;    '2018_06_02\Pyro_reference_intermediate_standard_res\Pyro_ref_180602_0021_avg_20.ifg' $
;    ]

;  ;
;  ; Vacuum, Hi-Res, VDI
;  ;
;  dataFiles = [ $
;    '2018_05_30\TES_reference_trans_hi_res\TES_vac_180530_0051_avg_50.ifg', $
;;    '2018_05_28\HEB_reference_trans_hi_res_clipped\'
;    '2018_05_31\TES_VDI_trans_hi_res\TES_vdi_hg_180531_0045_avg_10.ifg', $
;    '2018_06_01\HEB_vdi_trans_hi_res\HEB_VDI_180601_0013_avg_10.ifg', $
;    '2018_05_31\Pyro_VDI_trans_hi_res\pyro_vdi_180531_0011_avg_10.ifg' $
;    ]
;;


  foreach dataFile, dataFiles do begin
    bs_dat = SOLOIST_FTS_READ_FILE(rootDir+dataFile)
    ;whR = WHERE(bs_dat.opd GE 1. AND bs_dat.opd LE 2.)
    whR = WHERE(bs_dat.opd GE 0.1 AND bs_dat.opd LE 0.2)
    print, dataFile, (MAX(bs_dat.signal)-MIN(bs_dat.signal))*1000., STDDEV(bs_dat.signal[whR]-MEDIAN(bs_dat.signal[whR]))*1000.
  endforeach
  ;
  ;  dataDir = 'R:\data_archive\RRCAT\Data\2018_05_29\MCT\Gold_Mirror\'
  ;  dataFile = 'MCT_refl_180529_0051_avg_50.ifg'
  ;  bs_dat = SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  ;
  ;
  ;  dataDir = 'R:\data_archive\RRCAT\Installation\2018_09_10\'
  ;  dataFile = 'Sample_Reflection_MCT_GM_180910_1432_avg_50.ifg'
  ;  rrcat_dat = RRCAT_SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  ;  p=plot(rrcat_dat.opd, (rrcat_dat.signal-MEDIAN(rrcat_dat.signal))/5., title = 'Reflection (RRCAT)', $
  ;    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)
  ;
  ;  dataDir = 'R:\data_archive\RRCAT\Data\2018_05_29\MCT\Gold_Mirror\'
  ;  dataFile = 'MCT_refl_180529_0051_avg_50.ifg'
  ;  bs_dat = SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  ;  p=plot(bs_dat.opd, bs_dat.signal/200., title = 'Reflection (Blue Sky)', $
  ;    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)
  ;
  ;  whR = WHERE(rrcat_dat.opd GE 1. AND rrcat_dat.opd LE 2.)
  ;  print, 'RRCAT ', (MAX(rrcat_dat.signal)-MIN(rrcat_dat.signal))/5.*1000., STDDEV(rrcat_dat.signal[whR]-MEDIAN(rrcat_dat.signal[whR]))/5.*1000.
  ;  print, 'BS ', (MAX(bs_dat.signal)-MIN(bs_dat.signal))/200.*1000., STDDEV(bs_dat.signal[whR]-MEDIAN(bs_dat.signal[whR]))/200.*1000.
  ;  STOP
  ;
  ;  ; Transmission
  ;  dataDir = 'R:\data_archive\RRCAT\Installation\2018_09_10\'
  ;  dataFile = 'Reference_Transmission_MCT_GM_180910_1353_avg_20.ifg'
  ;  rrcat_dat = RRCAT_SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  ;  p=plot(rrcat_dat.opd, (rrcat_dat.signal-MEDIAN(rrcat_dat.signal))/5., title = 'Transmission (RRCAT)', $
  ;    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)
  ;
  ;
  ;  dataDir = 'R:\data_archive\RRCAT\Data\2018_06_01\MCT_reference_trans_standard_res\'
  ;  dataFile = 'MCT_REF_180601_0151_avg_50.ifg'
  ;  bs_dat = SOLOIST_FTS_READ_FILE(dataDir+dataFile)
  ;  p=plot(bs_dat.opd, bs_dat.signal/200., title = 'Transmission (Blue Sky)', $
  ;    xtitle = 'OPD (cm)', ytitle = 'Signal (V)', xstyle=1, ystyle=1, thick=2)
  ;
  ;  whR = WHERE(rrcat_dat.opd GE 1. AND rrcat_dat.opd LE 2.)
  ;  print, 'RRCAT ', (MAX(rrcat_dat.signal)-MIN(rrcat_dat.signal))/5.*1000., STDDEV(rrcat_dat.signal[whR]-MEDIAN(rrcat_dat.signal[whR]))/5.*1000.
  ;  print, 'BS ', (MAX(bs_dat.signal)-MIN(bs_dat.signal))/200.*1000., STDDEV(bs_dat.signal[whR]-MEDIAN(bs_dat.signal[whR]))/200.*1000.
  STOP
end