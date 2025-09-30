; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
;	Unauthorized reproduction prohibited without touting Darkhan's
;	name. Please help me live forever by continuing the tradition
;	of honoring science nerds of the past by putting their name in
;	your code that uses theirs. 
;
;+
; NAME:
; EXTRACT_TEXP
;
; PURPOSE:
; This here procedure extracts effective exposure time values from IRAC mosaic FITS files by measuring mean pixel values in background annuli around specified target positions.
;
; CATEGORY:
; Astronomy, IRAC Data Analysis, Exposure Time Measurement
;
; CALLING SEQUENCE:
; EXTRACT_TEXP, Config_File
;
; INPUTS:
; Config_File: The configuration file containing input/output paths and processing parameters including input coordinate list, output file, data directory, and annulus dimensions.
;
; OUTPUTS:
; The procedure writes an output file containing effective exposure times for each target across all four IRAC channels.
;
; PROCEDURE:
; Reads target coordinates and processes each through all IRAC channels, extracts background annulus measurements from mosaic FITS files, and calculates mean values representing effective exposure times.
;
; EXAMPLE:
; Extract exposure times for a list of magnetar positions:
;
; EXTRACT_TEXP, 'config_texp.coldat'
;
; MODIFICATION HISTORY:
; 	Written by:	Darkhan Nurzhakyp 2025 September 30
;	September,2025	Any additional mods get described here.  Remember to
;			change the stuff above if you add a new keyword or
;			something!
;-

;-----------------------------------------------------------------
;-----------------------------------------------------------------
;                             Main Routine
;-----------------------------------------------------------------
;-----------------------------------------------------------------
pro extract_texp, config_file
compile_opt idl2

    ; Read config.coldat using readcoldat
    readcoldat, config_file, config_data, comchar='#'

    input_coldat   = config_data[0,0]
    output_coldat  = config_data[1,0]
    data_path      = config_data[2,0]
    ;rap            = float(config_data[3,0])
    rin        = float(config_data[4,0])
    rout           = float(config_data[5,0])

    ; Read magnetars list
    readcoldat, input_coldat, data, comchar='#'
    nrows = n_elements(data) / 3
    texp = fltarr(nrows, 4) + !VALUES.F_NAN

    for i = 0, nrows-1 do begin
        folder = data[0, i]
        ra = data[1, i]
        dec = data[2, i]

        for ch = 1, 4 do begin
            mosaici_folder = data_path + '/' + folder + '/mosaici' + strtrim(ch,2) + '/Coadd/'
            fits_files = file_search(mosaici_folder + '*.fits', count=nfiles)
            if nfiles eq 0 then continue

            img = readfits(fits_files[0], hdr)
            adxy, hdr, ra, dec, xc, yc

            sz = size(img, /dimensions)
            ;if (x ge 0) and (x lt sz[0]) and (y ge 0) and (y lt sz[1]) then begin
            annulus_pixels = get_annulus(img, xc, yc, rin, rout)
            if n_elements(annulus_pixels) gt 0 then begin
               texp[i, ch-1] = mean(annulus_pixels, /nan)
            endif
            ;endif
        endfor
    endfor

    ; Write output
    test = file_test(output_coldat)
    openw, lun, output_coldat, /get_lun
    if ~test then printf, lun, '# name ch1_texp(s) ch2_texp(s) ch3_texp(s) ch4_texp(s)'
    for i = 0, nrows-1 do begin
        printf, lun, data[0,i], texp[i,0], texp[i,1], texp[i,2], texp[i,3], format='(A,4(1x,F8.2))'
    endfor
    free_lun, lun
end

