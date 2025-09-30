; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
;	Unauthorized reproduction prohibited without touting Darkhan's
;	name. Please help me live forever by continuing the tradition
;	of honoring science nerds of the past by putting their name in
;	your code that uses theirs. 
;
;+
; NAME:
; IRAC_LIMIT
;
; PURPOSE:
; This here procedure performs point source sensitivity analysis for IRAC data by placing scaled PRF/PSF models at multiple positions around a target coordinate, performing aperture photometry, and generating diagnostic plots.
;
; CATEGORY:
; Astronomy, Photometry, IRAC Data Analysis
;
; CALLING SEQUENCE:
; IRAC_LIMIT, Data_Path, Imname, Ra_Decimaldeg, Dec_Decimaldeg, Channel, Factor, Rap, Rbackin, Rbackout, Spacing, Prf_Path, Unit, Test_Unit
;
; INPUTS:
; Data_Path: The base directory path containing the IRAC mosaic data.
;
; Imname: The name identifier for the specific image/mosaic being analyzed.
;
; Ra_Decimaldeg: The right ascension of the target position in decimal degrees.
;
; Dec_Decimaldeg: The declination of the target position in decimal degrees.
;
; Channel: The IRAC channel number (1-4) being analyzed.
;
; Factor: The scaling factor to apply to the PRF when placing it in the image.
;
; Rap: The aperture radius in arcseconds for photometry measurements.
;
; Rbackin: The inner radius of the background annulus in arcseconds.
;
; Rbackout: The outer radius of the background annulus in arcseconds.
;
; Spacing: The spacing between test positions in pixels.
;
; Prf_Path: The directory path containing the PRF/PSF files.
;
; Unit: The file unit for outputting photometry results.
;
; Test_Unit: The file unit for test image output.
;
; KEYWORD PARAMETERS:
; PHOT: Set this keyword to perform aperture photometry on the placed PRFs and output results. The default is to not perform photometry.
;
; PAUSE: Set this keyword to pause execution after processing for inspection. The default is to not pause.
;
; VERBOSE: Set this keyword to display diagnostic information and generate plots. The default is to not display verbose output.
;
; TEST: Set this keyword to generate test images for validation. The default is to not generate test images.
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

pro irac_limit, data_path, imname, ra_decimaldeg, dec_decimaldeg, channel, factor, $
                rap, rbackin, rbackout, spacing, prf_path, unit, test_unit, $
                PHOT=phot, PAUSE=pause, VERBOSE=verbose, TEST=test
compile_opt IDL2

  if N_ELEMENTS(norm) EQ 0 then norm = 0

  ;=====READING IMAGE=====
  basename = data_path+'/'+imname+'/mosaici'+STRTRIM(channel,1)+'/Combine/'
  fits_files = file_search(basename + '*.fits', count=nfiles)
  if nfiles eq 0 then begin
     return
  endif
  temp = READFITS(basename+'mosaic.fits', header)
  data = temp
  
  ;=====GET PIXEL COORDS=====
  adxy, header, ra_decimaldeg, dec_decimaldeg, x_c, y_c
  sz = size(temp)

  ;=====READING PRF/PSF=====
  ;prf_filename = '070131_prfs_for_apex_v080827_ch'+STRTRIM(channel,1)+$
  ;               '/apex_sh_IRAC'+STRTRIM(channel,1)+'_col129_row129_x100.fits'
  prf_filename = prf_path+'/070131_prfs_for_apex_v080827_ch'+STRTRIM(channel,1)+$
                 '/apex_sh_IRAC'+STRTRIM(channel,1)+'_col129_row129_x100.fits'
  psf = READFITS(prf_filename)  

  ;=====APERTURE PARAMETERS=====
  fwhm_as = [1.66, 1.72, 1.88, 1.98]
  mos_aspp = 0.6
  fwhmmp = fwhm_as[channel-1] / mos_aspp ; fwhmmp = fw in mosaic pixels ; mos_aspp = mosaic arcsec per pixel
  apcor = [1.125, 1.120, 1.135, 1.221]
  psize_asec = [1.221, 1.213, 1.222, 1.220]
  rap = rap * psize_asec[channel-1] / mos_aspp
  rbackin = rbackin * psize_asec[channel-1] / mos_aspp
  rbackout = rbackout * psize_asec[channel-1] / mos_aspp ; all in mosaic pixels

  ;=====PLACING PARAMETERS=====
  nx = 3
  ny = 3

  ;=====WINDOW PARAMETERS=====
  IF keyword_set(verbose) THEN BEGIN
     WINDOW, 0, XSIZE=900, YSIZE=800
     ;!X.MARGIN = [10, 10]       ; Left and right margins
     ;!Y.MARGIN = [-1, 1]
  ENDIF
  
  ;=====MAIN PROCEDURE=====
     
   IF keyword_set(verbose) THEN BEGIN
   ;   ps_filename = './../plots/'+imname+'_factor'+STRTRIM(factors[kk],2)+'.ps'
   ;   SET_PLOT, 'PS'
   ;   DEVICE, FILENAME=ps_filename, /COLOR, /PORTRAIT
      !P.multi = [0,3,3]
   ENDIF
   
   FOR ii= 0, nx-1 DO BEGIN
      FOR jj= 0, ny-1 DO BEGIN

         ;=====GET POSITION=====
         x_offset = (ii-1) * spacing
         y_offset = (jj-1) * spacing
         x_pos = x_c + x_offset
         y_pos = y_c + y_offset
         
         im = data
         print, 'TESTING '+STRTRIM(factor)+': at ('+STRTRIM(x_pos,1) +','+STRTRIM(y_pos,1)+')'

         ;===========TEST IMAGE============
         IF keyword_set(test) THEN BEGIN
            test_image, im, imname, rap, rbackin, rbackout, apcor, ra_decimaldeg, dec_decimaldeg, $
                        x_pos, y_pos, sz, channel, factor, psf, test_unit, /verbose
         ENDIF

         ;=====PLACING PRF/PSF=====
         place_prf, im, channel, x_pos, y_pos, x_pos-fix(x_pos), y_pos-fix(y_pos), psf, factor, imout
         
         ;=====PLOTTING=====
         IF keyword_set(verbose) THEN BEGIN
            x1 = fix(x_c) - 15
            x2 = fix(x_c) + 15
            y1 = fix(y_c) - 15
            y2 = fix(y_c) + 15
            bgframe, imout[x1:x2, y1:y2], TITLE='X='+STRTRIM(x_pos,2)+' Y='+STRTRIM(y_pos,2)

            rel_x = x_pos - x1
            rel_y = y_pos - y1

            x_box = [rel_x-5, rel_x+5, rel_x+5, rel_x-5, rel_x-5]
            y_box = [rel_y-5, rel_y-5, rel_y+5, rel_y+5, rel_y-5]
         
            OPLOT, x_box, y_box, COLOR=0
         ENDIF
         
         ;=====PHOTOMETRY=====
         IF keyword_set(phot) THEN BEGIN
            circapphot, imout, x_pos, y_pos, rap, tot, imag, 1., npix, pixsig, $
                        magerr, rbackin=rbackin, bgndwidth=rbackout-rbackin, sigma=sigma
            result = {name:imname,ra:ra_decimaldeg,dec:dec_decimaldeg,ch:channel, $
                     xpos:x_pos,ypos:y_pos,factor:factor, $
                     phot:8.47*tot*apcor[channel-1], sigma:8.47*apcor[channel-1]*sigma}
            printf, unit, result.name, result.ra, result.dec, result.ch, result.xpos, $
                  result.ypos, result.factor, result.phot, result.sigma, $
                  FORMAT='(a-12, 2(f12.6), i6, 2(f12.6), i8, 2(f16.6))'
         ENDIF
   ENDFOR
   ENDFOR
   
   IF keyword_set(verbose) THEN BEGIN
      !P.multi = 0
         
      XYOUTS, 0.5, -0.9, imname+' PSF Scale Factor=' + STRTRIM(factor,2), /NORMAL, ALIGN=0.5, CHARSIZE=1.5
      ;DEVICE, /CLOSE
      ;SET_PLOT, 'X'
   ENDIF
   
   IF keyword_set(pause) THEN BEGIN
      print, 'paused... type .c to continue'
      stop
   ENDIF

end
