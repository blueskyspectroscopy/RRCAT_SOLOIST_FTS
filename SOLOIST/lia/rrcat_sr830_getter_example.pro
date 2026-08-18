
pro rrcat_sr830_getter_example

  ;use debug keyword if you want to print messages
  sr830=obj_new('SR830',port='COM9',baud=9600,data=8,parity='N',stop=1)

  result = sr830->getFreq(error = err)
  print, 'Frequency: ' + result

  result = sr830->getTau(error = err)
  strResult = rrcat_lia_translate_values(result, /TAU)
  print, 'Time Constant: ' + result + ' ' + strResult

  result = sr830->getSens(error = err)
  strResult = rrcat_lia_translate_values(result, /SENS)
  print, 'Sensitivity: ' + result + ' ' + strResult

  result = sr830->getReserve(error = err)
  strResult = rrcat_lia_translate_values(result, /RESERVE)
  print, 'Reserve: ' + result + ' ' + strResult

  result = sr830->getFilter(error = err)
  strResult = rrcat_lia_translate_values(result, /FILT)
  print, 'Filter: ' + result + ' ' + strResult

  result = sr830->getPhase(error = err)
  print, 'Phase: ' + result 

  result = sr830->getCoupling()
  strResult = rrcat_lia_translate_values(result, /COUP)
  print, 'Coupling: ' + result + ' ' + strResult

  result = sr830->getGrounding(error = err)
  strResult = rrcat_lia_translate_values(result, /GND)
  print, 'Grounding: ' + result + ' ' + strResult


  STOP
  obj_destroy,sr830 ;calls cleanup method and destroys the object

end