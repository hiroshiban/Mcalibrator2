function result=test_iData_clabel

  a=iData(rand(10,10,10,10));

  clabel(a,'C');
  
  if strcmp(clabel(a), 'C')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
