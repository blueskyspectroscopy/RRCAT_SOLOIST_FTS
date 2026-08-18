FUNCTION RRCAT_KK_STITCH_SPECTRUM, info

  wn_1 = *info.wn_1
  spec_1 = *info.spec_1
  wn_2 = *info.wn_2
  spec_2 = *info.spec_2
  wn_3 = *info.wn_3
  spec_3 = *info.spec_3
  wn_4 = *info.wn_4
  spec_4 = *info.spec_4
  
  wn = *info.wn_1
  spec = *info.spec_1

  minWn1 = info.file_1_min_wn_field->get_value()
  maxWn1 = info.file_1_max_wn_field->get_value()
  minWn2 = info.file_2_min_wn_field->get_value()
  maxWn2 = info.file_2_max_wn_field->get_value()
  minWn3 = info.file_3_min_wn_field->get_value()
  maxWn3 = info.file_3_max_wn_field->get_value()
  minWn4 = info.file_4_min_wn_field->get_value()
  maxWn4 = info.file_4_max_wn_field->get_value()


  wh1 = WHERE(wn GE minWn1 AND wn LE maxWn1)
  wh2 = WHERE(wn GE minWn2 AND wn LE maxWn2)
  wh3 = WHERE(wn GE minWn3 AND wn LE maxWn3)
  wh4 = WHERE(wn GE minWn4 AND wn LE maxWn4)

  spec[wh1] = spec_1[wh1]
  spec[wh2] = spec_2[wh2]
  spec[wh3] = spec_3[wh3]
  spec[wh4] = spec_4[wh4]

  dWn = wn[1] - wn[0]
  fact = info.high_f_field->get_value()
  a = spec[n_ELEMENTS(spec)-1]/(wn[n_ELEMENTS(wn)-1])^(fact)
  nWn = LONG((a/0.0001)^(1/ABS(fact))-MAX(wn))
  IF nWn GT 750000 THEN nWn = 750000
  tailWn = (DINDGEN(nWn/dWn)+1)*dWn+MAX(wn)
  tailSpec = a*tailWn^(fact)

  wn = [wn, tailWn]
  spec = [spec, tailSpec]
    
  outDat = {wn:wn, spec:spec}
  return, outDat
END