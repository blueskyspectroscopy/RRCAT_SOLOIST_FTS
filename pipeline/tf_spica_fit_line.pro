;
;    line amplitude (par[0])
;    line centre (par[1])
;    1/line resolution (par[2])
;    continuum (par[3] + par[4]*x + par[5]*x^2 + ...)
;
;

FUNCTION TF_SPICA_fit_line, wn, val
  sincArg = !PI*val[2]*(wn-val[1])

  wh = WHERE(sincArg EQ 0.0, whCount)
  sinc = val[0]*sin(sincArg)/(sincArg)
  IF whCount GT 0 THEN BEGIN
    sinc[wh] = val[0]
  ENDIF

  bg = val[3]

  FOR i=0, N_ELEMENTS(val)-5 DO BEGIN
   bg = bg + val[i+4]*wn^(i+1)
  ENDFOR

  fit = bg+sinc

  RETURN, fit

END