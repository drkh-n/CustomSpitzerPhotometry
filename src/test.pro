; Copyright (c) 2000-2050, Banzai Astrophysics.  All rights reserved.
;	Unauthorized reproduction prohibited without touting Darkhan's
;	name. Please help me live forever by continuing the tradition
;	of honoring science nerds of the past by putting their name in
;	your code that uses theirs. 
;
;+
; NAME:
; TEST_IMAGE
;
; PURPOSE:
; This here procedure creates a test image with simulated noise and places a scaled PRF at a specified position to validate photometry procedures and output results.
;
; CATEGORY:
; Astronomy, Testing, Photometry Validation
;
; CALLING SEQUENCE:
; TEST_IMAGE, Im, Imname, Rap, Rbackin, Rbackout, Apcor, Ra_Decimaldeg, Dec_Decimaldeg, X_pos, Y_pos, Sz, Channel, Factor, Psf, Test_Unit
;
; INPUTS:
; Im: The original input image array used to determine noise characteristics.
;
; Imname: The name identifier for the image being tested.
;
; Rap: The aperture radius in pixels for photometry measurements.
;
; Rbackin: The inner radius of the background annulus in pixels.
;
; Rbackout: The outer radius of the background annulus in pixels.
;
; Apcor: The aperture correction factors for each IRAC channel.
;
; Ra_Decimaldeg: The right ascension of the target position in decimal degrees.
;
; Dec_Decimaldeg: The declination of the target position in decimal degrees.
;
; X_pos: The x-coordinate in the image where the PRF center is placed.
;
; Y_pos: The y-coordinate in the image where the PRF center is placed.
;
; Sz: The dimensions of the input image array.
;
; Channel: The IRAC channel number (1-4) being tested.
;
; Factor: The scaling factor to apply to the PRF when placing it in the test image.
;
; Psf: The Point Spread Function (PRF) array to be placed into the test image.
;
; Test_Unit: The file unit for outputting test results.
;
; KEYWORD PARAMETERS:
; VERBOSE: Set this keyword to print diagnostic information during execution. The default is to not print verbose output.
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

pro test_image, im, imname, rap, rbackin, rbackout, apcor, ra_decimaldeg, dec_decimaldeg, $
                x_pos, y_pos, sz, channel, factor, psf, test_unit, verbose=verbose
compile_opt IDL2

  print, '=====START TEST====='
  sig = stdev(im[x_pos-7:x_pos+7, y_pos-7:y_pos+7])
  
  im_test = randomn(seed, sz[1], sz[2])*sig

  place_prf, im_test, channel, x_pos, y_pos, x_pos-fix(x_pos), y_pos-fix(y_pos), psf, factor, imout
  
  ;--- photometry
  circapphot, imout, x_pos, y_pos, rap, phot, imag, 1., npix, $
              pixsig, magerr, rbackin=rbackin, bgndwidth=$
              rbackout-rbackin, sigma=sigma

  ;--- save results
  result = {name:imname,ra:ra_decimaldeg,dec:dec_decimaldeg,ch:channel, $
            xpos:x_pos,ypos:y_pos,factor:factor, $
            phot:8.47*apcor[channel-1]*phot, sigma:8.47*apcor[channel-1]*sigma, $
            tot:total(imout[x_pos-7:x_pos+7,y_pos-7:y_pos+7]), sig:sig}
  printf, test_unit, result.name, result.ra, result.dec, result.ch, result.xpos, $
          result.ypos, result.factor, result.phot, result.sigma, result.tot, result.sig, $
          FORMAT='(a-12, 2(f12.6), i6, 2(f12.6), i8, 4(f16.6))'
  
  print, '=====FINISH TEST====='

end
