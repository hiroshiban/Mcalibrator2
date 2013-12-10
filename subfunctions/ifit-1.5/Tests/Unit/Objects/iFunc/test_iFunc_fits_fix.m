function result = test_iFunc_fits_fix

  a=load(iData, [ ifitpath 'Data/sv1850.scn' ]);
  p=fits(a, 'gauss', [], 'fminralg', [ 1 0 0 0 ]);
  % p= 0.5936    1.0008   -0.0037    0.0002
  
  if abs(max(abs([ 0.5936         1.0008      0.0035         0.0002 ])-abs(p))) < 0.01
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end 
