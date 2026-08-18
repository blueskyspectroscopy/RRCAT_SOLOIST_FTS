pro tf_spectral_leak_April2010

	u = [10, 12, 15, 20, 50, 100]

	D3 = 3.8e-4	; thickness of film in cm. Best fit: 6.2 um
	D6 = 6.25e-4
	D12 = 12.5e-4 ; thickness is 12.5 um
	DHDPE = 1.58e-1 ; HDPE thickness is 1.58 mm
	DPS = 1.58e-1 ; PS thickness is 1.58 mm
	n = 1.5		; refractive index of film material
	nHDPE = 1.54   ; refractive index of film material
	nPS = 1.58   ; refractive index of film material

	wn = findgen(101)*10

	R = (n - 1.)^2 / (n + 1.)^2		; reflection
	RHDPE = (nHDPE - 1.)^2 / (nHDPE + 1.)^2   ; reflection
	RPS = (nPS - 1.)^2 / (nPS + 1.)^2   ; reflection


	RE3 = 8.* (1. - R)^2 * R * cos(2. * !pi * (wn * D3 * sqrt(n^2 - .5) + .25))^2
;	RE3 *= PLANCK_EQ(wn, 800+273.15)

	RE6 = 8.* (1. - R)^2 * R * cos(2. * !pi * (wn * D6 * sqrt(n^2 - .5) + .25))^2
;	RE6 *= PLANCK_EQ(wn, 800+273.15)

	RE12 = 8.* (1. - R)^2 * R * cos(2. * !pi * (wn * D12 * sqrt(n^2 - .5) + .25))^2
;	RE12 *= PLANCK_EQ(wn, 800+273.15)

HDPE = 8.* (1. - RHDPE)^2 * RHDPE * cos(2. * !pi * (wn * DHDPE * sqrt(nHDPE^2 - .5) + .25))^2
PS = 8.* (1. - RPS)^2 * RPS * cos(2. * !pi * (wn * DHDPE * sqrt(nPS^2 - .5) + .25))^2
; RE12 *= PLANCK_EQ(wn, 800+273.15)



;		ps_plot_setup, FONT_SIZE=12

	zoomplot, wn, HDPE, xr=[0,1000], yr=[0,0.4], thick=4, xstyle=8, $
			ticklen=0.04, xtitle='Wavenumber (cm!E- 1!N)',ytitle='Efficiency', xthick=4, ythick=4, $
		;	charsize=2.0, charthick=2.0, $
			symsize=1.0, obj_ref=pObj ;Title='Mylar Beamsplitter Fringes';, background=9, color=0;, YTICKINTERVAL=0.2
	;xyouts, 200,0.47,'HDPE Fringes', charsize=2, charthick=2
	;legend, ['1.58 mm  ', '1.58 mm  '], psym=[0,0], colors=[0,2],pos=[100,0.38],thick=[4,4]
	;non_linear_axis, 1e4/u, u, format = '(i4.0)', title = 'Wavelength (!9m!X!Nm)', charsize=1.25, thick=4
	pObj->add, wn, PS, color='red', thick=4

;		ps_plot_close


	stop

END
