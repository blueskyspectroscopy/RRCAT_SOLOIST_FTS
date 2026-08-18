PRO tf_rrcat_avg_ifgms_blueSky
   rootDir = 'R:\data_archive\RRCAT\Data\'
   dataDirs = [ $
    '2018_06_01\Pyro_Gold_refl_standard_res\', $
    '2018_05_30\HEB_reference_trans_hi_res_clipped\' $
    ]
   dataDirs = ['2018_05_28\Gold_reflection_heb_standard_res']
   foreach dataDir, dataDirs do begin
     dataFiles = FILE_SEARCH(rootDir+dataDir, '*.ifg', COUNT = fCount)
     wh = dataFiles.contains('_avg')
     w = WHERE(wh EQ 0)
     dataFiles = dataFiles[w]
     IF fCount EQ 0 THEN STOP
     
     allSig = []
     foreach dataFile, dataFiles, iFile do begin
      bs_dat = SOLOIST_FTS_READ_FILE(dataFile)
      allSig =[[allSig], [bs_dat.signal]]
     endforeach
     whR = WHERE(bs_dat.opd GE 1. AND bs_dat.opd LE 2.)
     avgSig = TOTAL(allSig, 2)/(SIZE(allSig))[2]
     print, dataFile, (MAX(avgSig)-MIN(avgSig))*1000., STDDEV(avgSig[whR]-MEDIAN(avgSig[whR]))*1000. 
     STOP
   endforeach


END