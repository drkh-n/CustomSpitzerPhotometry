pro test_image, im, imname, rap, rbackin, rbackout, apcor, ra_decimaldeg, dec_decimaldeg, $
                x_pos, y_pos, sz, channel, factor, psf, test_unit, verbose=verbose
  
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
