function result = test_iFunc_fits_options
  a=load(iData, [ ifitpath 'Data/sv1850.scn' ]);
  options=fminimfil('defaults');
  options.TolFun=0.01;
  p=fits(a, 'gauss', [], options);
  
  if abs(max(abs([ 0.61         1.0008      0.0035         0.0001 ])-abs(p))) < 0.01
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end 
