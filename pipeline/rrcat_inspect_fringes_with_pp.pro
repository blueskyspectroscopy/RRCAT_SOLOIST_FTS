PRO rrcat_inspect_fringes_with_pp

  nHDPE = 1.54   ; refractive index of film material
  nPS = 1.58   ; refractive index of film material
  DHDPE = 1.58e-1 ; HDPE thickness is 1.58 mm
  DPS = 1.58e-1 ; PS thickness is 1.58 mm
  nPP = 1.54
  dPP = 110.e-4


  RHDPE = (nHDPE - 1.)^2 / (nHDPE + 1.)^2   ; reflection
  RPS = (nPS - 1.)^2 / (nPS + 1.)^2     ; reflection
  RPP = (nPP - 1.)^2 / (nPP + 1.)^2     ; reflection


  ;  rootDir = 'V:\RRCAT\Data\2018_05_29\'
  
  ;
  ; HEB
  ;
;  xmax = 100
;  ymax = 100
;  rootDir = 'U:\RRCAT\Data\2018_05_31\results\Transmission\'
;  rootDirRef = 'U:\RRCAT\Data\2018_05_30\results\Transmission\'
;
;  refFile = 'Reference_trans_HEB_0.2res_processed_abs.spc'
;  hdpeFile = 'HDPE_trans_HEB_0.2res_processed_abs.spc'
;  psFile = 'PolyStyrene_trans_HEB_0.2res_processed_abs.spc'

  ;
  ; TES
  ;
  xmax = 800
  yMax = 25
  rootDir = 'U:\RRCAT\Data\2018_05_30\results\Transmission\'
  rootDirRef = 'U:\RRCAT\Data\2018_05_30\results\Transmission\'

  refFile = 'Reference_trans_TES_0.2res_processed_abs.spc'
  hdpeFile = 'HDPE_trans_TES_0.2res_processed_abs.spc'
  psFile = 'PolyStyrene_trans_TES_0.2res_processed_abs.spc'

  read_spc, rootDirRef+refFile, refWn, refSpec
  read_spc, rootDir+hdpeFile, hdpeWn, hdpeSpec
  read_spc, rootDir+psFile, psWn, psSpec

  HDPE = 8.* (1. - RHDPE)^2 * RHDPE * cos(2. * !pi * (hdpeWn * DHDPE * sqrt(nHDPE^2 - .5) + .25))^2
  PS = 8.* (1. - RPS)^2 * RPS * cos(2. * !pi * (psWn * DPS * sqrt(nPS^2 - .5) + .25))^2
  ;PP = 8.* (1. - RPP)^2 * RPP * cos(2. * !pi * (refWn * DPP * sqrt(nPP^2 - .5) + .25))^2
  PP = 8.* (1. - RHDPE)^2 * RHDPE * cos(2. * !pi * (refWn * 1.5e-1 * sqrt(nHDPE^2 - .5) + .25))^2


  p = plot(refWn, refSpec, xrange = [0, xmax], yrange = [-.5, ymax], thick = 2,$
    title = 'Reference', $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)')
  p = plot(refWn, pp*30+30, thick = 2, color = 'green', /overpl)

  p = plot(hdpeWn, hdpeSpec, xrange = [0, xmax], yrange = [-.5, ymax], thick = 2,$
    title = 'HDPE', $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)')
  p = plot(hdpeWn, hdpe*25.+12.5, thick = 2, color = 'blue', /overpl)

  p = plot(psWn, psSpec, xrange = [0, xmax], yrange = [-.5, ymax], thick = 2,$
    title = 'Polystyrene', $
    xtitle = 'Wavenumber (cm$^{-1}$)', ytitle = 'Signal (a. u.)')
  p = plot(psWn, ps*10+10, thick = 2, color = 'red', /overpl)

  STOP
END