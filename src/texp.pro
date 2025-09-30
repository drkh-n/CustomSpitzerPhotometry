; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
;	Unauthorized reproduction prohibited without touting Darkhan's
;	name. Please help me live forever by continuing the tradition
;	of honoring science nerds of the past by putting their name in
;	your code that uses theirs. 
;
;+
; NAME:
;	EXTRACT_TEXP
;
; PURPOSE:
;	This procedure extracts the local exposure time (`texp`) around the target 
;	right ascension (RA) and declination (Dec) from FITS images. For each channel 
;	(1 to 4), it finds the coadded mosaic FITS file, converts RA/Dec to pixel 
;	coordinates, and computes the average value in a 5x5 pixel box centered on the 
;	target position.
;
; CATEGORY:
;	Astronomy, Image Processing, Photometry
;
; CALLING SEQUENCE:
;	EXTRACT_TEXP, Input_Coldat, Output_Coldat, Data_Path
;
; INPUTS:
;	Input_Coldat:  A string specifying the path to the input coldat file containing 
;	               target names, RA, and Dec.
;
;	Output_Coldat: A string specifying the path where the output coldat with extracted 
;	               exposure times will be written.
;
;	Data_Path:     A string representing the base directory where mosaici data folders 
;	               are located.
;
; OPTIONAL INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	This procedure writes a file (`Output_Coldat`) containing the name of each object 
;	and its average exposure time in a 5x5 box around the target for channels 1 through 4.
;
; OPTIONAL OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	- If a mosaic FITS file is not found for a given channel, a NaN is stored.
;	- Overwrites the output file if it already exists.
;
; RESTRICTIONS:
;	- Assumes input coldat contains a 3-row structure: folder names, RA, and Dec.
;	- Requires `readcoldat`, `adxy`, and `READFITS` procedures to be available.
;
; PROCEDURE:
;	1. Reads the coldat table and initializes a NaN array for storing exposure times.
;	2. Iterates over each source and channel.
;	3. Searches for the FITS file in the expected path.
;	4. Converts RA/Dec to (x, y) pixel coordinates in the FITS image.
;	5. Extracts a 5x5 pixel box around the source position.
;	6. Computes the mean value of the box and stores it.
;	7. Writes all results to the output coldat file.
;
; EXAMPLE:
;	Extract exposure times for a set of sources and save to a file:
;
;		EXTRACT_TEXP, 'input_coldat.coldat', 'output_texp.coldat', '/data/irac/'
;
; MODIFICATION HISTORY:
;	Written by: Darkhan Nurzhakyp, 2025 July 7
;	Initial version.
;-

;-----------------------------------------------------------------
;               Mini-Routines (main routine comes last)
;-----------------------------------------------------------------


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

