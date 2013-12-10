function result = test_iFunc_fits_constraints

  a=load(iData, [ ifitpath 'Data/sv1850.scn' ]);
  p=fits(a, 'gauss', [], 'fminimfil', [ 0.5 0.8 -1 0 ], [ 1 1.2 1 1 ]);
  
  if abs(max(abs([ 0.62         1.0008      0.0035         0.0001 ])-abs(p))) < 0.01
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end 
