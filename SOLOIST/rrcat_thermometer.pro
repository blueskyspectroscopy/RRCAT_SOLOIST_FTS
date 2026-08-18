;+
; NAME:
; rrcat_thermometer.pro
;
; PURPOSE:
; "This function is for use with the RRCAT QFI Detector Temperature Calibration.
; This function takes a volteage read from the module and returns the
; corresponding temperature in kelvin."
; Sensor Model:   QNbB/PTC(2 + XBi)
; Serial Number:  2432
; Data Format:    2      (Volts vs. Kelvin)
; SetPoint Limit: 475.0      (Kelvin)
; Temperature coefficient:  1 (Negative)
; Number of Breakpoints:   88
;
; CATEGORY:
; Diode thermemeter for Dual-channel HEB/TES detector cryostat 
;
; CALLING SEQUENCE:
; result = rrcat_thermometer(voltage)
; 'voltage' can be a single input or an array
;
; INPUTS:
; Voltage in Volts
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
; Temperature in Kelvin
;
;
; RESTRICTIONS:
;
;
; PROCEDURE:
;
; EXAMPLE:
;  result = rrcat_thermometer(voltage)
; 'voltage' can be a single input or an array
;
; MODIFICATION HISTORY:
;   Written by: Trevor Fulton
;   June 12, 2019
;
; Copyright 2019, Blue Sky Spectroscopy Inc.
;   All rights reserved.
;-
function rrcat_thermometer, voltage

    ; This is the data to convolute with. The left column is the temperature in
    ; kelvin and the right column in the voltage in volts
    conv = [           $
        [300, 0.5795], $
        [285, 0.6055], $
        [265, 0.6488], $
        [250, 0.6846], $
        [235, 0.7170], $
        [220, 0.7488], $
        [205, 0.7811], $
        [190, 0.8131], $
        [180, 0.8338], $
        [170, 0.8547], $
        [160, 0.8753], $
        [150, 0.8953], $
        [145, 0.9051], $
        [140, 0.9150], $
        [135, 0.9249], $
        [130, 0.9350], $
        [125, 0.9446], $
        [120, 0.9541], $
        [115, 0.9635], $
        [110, 0.9728], $
        [105, 0.9820], $
        [100, 0.9911], $
        [95,  0.9998], $
        [90,  1.0086], $
        [85,  1.0175], $
        [80,  1.0259], $
        [75,  1.0346], $
        [70,  1.0431], $
        [65,  1.0516], $
        [58,  1.0634], $
        [52,  1.0733], $
        [46,  1.0826], $
        [40,  1.0916], $
        [39,  1.0930], $
        [36,  1.0975], $
        [34,  1.1006], $
        [33,  1.1021], $
        [32,  1.1037], $
        [31,  1.1054], $
        [30,  1.1070], $
        [29,  1.1088], $
        [28,  1.1108], $
        [27,  1.1129], $
        [26,  1.1156], $
        [25,  1.1190], $
        [24,  1.1243], $
        [23,  1.1339], $
        [22,  1.1534], $
        [21,  1.1772], $
        [20,  1.1985], $
        [19,  1.2166], $
        [18,  1.2337], $
        [17,  1.2516], $
        [16,  1.2705], $
        [15,  1.2900], $
        [14,  1.3111], $
        [13,  1.3345], $
        [12,  1.3600], $
        [11,  1.3883], $
        [10,  1.4218], $
        [9,   1.4617], $
        [8,   1.5091], $
        [7,   1.5624], $
        [6,   1.6155], $
        [5,   1.6679], $
        [4,   1.7167], $ 
        [3,   1.7561], $
        [2.5, 1.7710] $
    ]
    
    ; Interpolate by convolution
    return, interpol(conv[0, *], conv[1, *], voltage)
end