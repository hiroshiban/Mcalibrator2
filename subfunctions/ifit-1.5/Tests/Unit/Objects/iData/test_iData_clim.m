function result=test_iData_clim

  a=iData(rand(10,10,10,10))
  clim(a);
  clim(a, [2 8]);
  
  result = [ 'OK     ' mfilename ];
