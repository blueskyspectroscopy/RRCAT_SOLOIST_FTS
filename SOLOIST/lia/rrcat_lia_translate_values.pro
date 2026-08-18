;+
; NAME:
; rrcat_lia_translate_values
;
; PURPOSE:
; This function converts the string returned by the LIA to something meaningful.
;
; CATEGORY:
; RRCAT SOLOIST FTS
;
; CALLING SEQUENCE:
; struct = rrcat_lia_translate_values(valStr, /TAU, /SENS, /RESERVE, /FILTER, /COUP, /GND)
;
; INPUTS:
; valStr: The string returned by the LIA
;
; KEYWORDS:
; TAU: Set this keyword translate tau values.
; SENS: Set this keyword translate sensitivity values.
; RESERVE: Set this keyword translate reserve values.
; FILTER: Set this keyword translate filter values.
; COUP: Set this keyword translate coupling values.
; GND: Set this keyword translate ground values.
;
; MODIFICATION HISTORY:
; 09 Aug 2019 (TRF): Fixed bug in translation of TAU. Returns ERROR if case
;                    statement finds no matches.
;
;-
FUNCTION rrcat_lia_translate_values, valStr, TAU=TAU, SENS=SENS, RESERVE=RESERVE, FILTER=FILTER, COUP=COUP, GND=GND

  val = FIX(valStr)
  IF KEYWORD_SET(TAU) THEN BEGIN
    CASE val OF
      0: retVal = '10 us'
      1: retVal = '30 us'
      2: retVal = '100 us'
      3: retVal = '300 us'
      4: retVal = '1 ms'
      5: retVal = '3 ms'
      6: retVal = '10 ms'
      7: retVal = '30 ms'
      8: retVal = '100 ms'
      9: retVal = '300 ms'
      10: retVal = '1 s'
      11: retVal = '3 s'
      12: retVal = '10 s'
      13: retVal = '30 s'
      14: retVal = '100 s'
      15: retVal = '300 s'
      16: retVal = '1 ks'
      17: retVal = '3 ks'
      18: retVal = '10 ks'
      19: retVal = '30 ks'
      else: retVal = 'ERROR' ; error
    ENDCASE
  ENDIF

  IF KEYWORD_SET(SENS) THEN BEGIN
    sensstrs = ['2 nV/fA','5 nV/fA','10 nV/fA','20 nV/fA','50 nV/fA','100 nV/fA','200 nV/fA','500 nV/fA',$
      '1 uV/pA','2 uV/pA','5 uV/pA','10 uV/pA','20 uV/pA','50 uV/pA','100 uV/pA','200 uV/pA','500 uV/pA',$
      '1 mV/nA','2 mV/nA','5 mV/nA','10 mV/nA','20 mV/nA','50 mV/nA','100 mV/nA','200 mV/nA','500 mV/nA',$
      '1 V/uA']
    retVal = sensstrs[val]
  ENDIF

  IF KEYWORD_SET(RESERVE) THEN BEGIN
    resstrs = ['High', 'Normal', 'Low Noise']
    retVal = resstrs[val]
  ENDIF

  IF KEYWORD_SET(FILTER) THEN BEGIN
    filtstrs = ['6 dB/oct', '12 dB/oct', '18 dB/oct', '24 dB/oct']
    retVal = filtstrs[val]
  ENDIF

  IF KEYWORD_SET(COUP) THEN BEGIN
    coupstrs = ['Float', 'Ground']
    retVal = coupstrs[val]
  ENDIF

  IF KEYWORD_SET(GND) THEN BEGIN
    gndstrs = ['AC', 'DC']
    retVal = gndstrs[val]
  ENDIF

  return, retVal
END