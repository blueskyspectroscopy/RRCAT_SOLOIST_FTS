FUNCTION RRCAT_SOLOIST_FTS_GET_DIO_BITVAL, dio

  retVal = dio.metrology + 2*dio.scanning + 4*dio.bit2 + 8*dio.bit3
  return, retVal

END