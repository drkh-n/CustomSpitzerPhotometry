pro simtar_test_setup
compile_opt IDL2

  ;------------------------------------------------------------
  ; Test A: Simulated Target Setup
  ;------------------------------------------------------------

  ;--- Load mosaic FITS image
  im = readfits('../simtar_partial/1e2259+586/mosaici1/Combine/mosaic.fits', hdr)
  sz = size(im)

  ;--- Load PRF and insert into empty image
  prf = readfits('../prf/070131_prfs_for_apex_v080827_ch1/apex_sh_IRAC1_col129_row129_x100.fits')
  
  ;--- Target coordinates (RA, DEC in degrees)
  ra  = 345.28455
  dec = 58.854317

  ;--- Convert RA/DEC to pixel coordinates
  adxy, hdr, ra, dec, xc, yc

  ;--- Estimate local noise (standard deviation in a small box)
  rad = 7
  sig = stdev(im[xc-rad:xc+rad, yc-rad:yc+rad])
  print, 'Estimated noise σ = ', sig

  ;--- Create simple simulated image with Gaussian noise
  seed = 42
  simpleim = randomn(seed, sz[1], sz[2]) * sig

  prfim = fltarr(sz[1], sz[2])
  print, 'PRF dimensions: ', sz[1], sz[2]
  
  ;F_4u01= 5 (uJy)
  ;prf= 3.75407e-05
  ;scale_factor = F_4u01 / prf = 5 / prf
  F_4u01 = 10.
  norm_prf = prf / total(prf)
  prfn = norm_prf
  
  ; Place PRF at target coordinates
  place_prf, simpleim, 1, xc, yc, 0, 0, prf, F_4u01, imout, /verbose 

  tot  = total(imout[xc-25:xc+25,yc-26:yc+26])
  print, 'Total flux at given position = ', tot

  ;------------------------------------------------------------
  ; Save simulated image
  ;------------------------------------------------------------
  writefits, '../simpletest/simpleim1.fits', imout, hdr

  ;------------------------------------------------------------
  ; Perform circular aperture photometry
  ;------------------------------------------------------------
  circapphot, imout, xc, yc, 25.0, phot, imag, 1.0, npix, pixsig, magerr, $
              rbackin=35., bgndwidth=10., sigma=sigma

  print, 'Aperture photometry results:'
  print, '  Total flux = ', phot
  print, '  σ (background noise) = ', sigma

  stop

end
