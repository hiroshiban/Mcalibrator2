function result=test_iData_fits

  a= load(iData, [ ifitpath 'Data/sv1850.scn' ]);
  p = fits(a,'','','fminpowell');
  
  if abs(max(abs([ 0.61         1.0008      0.0035         0.0001 ])-abs(p))) < 0.03
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
