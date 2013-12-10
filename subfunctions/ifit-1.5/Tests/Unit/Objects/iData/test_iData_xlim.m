function result=test_iData_xlim

  a=iData(1:50);
  xlim(a);
  xlim(a, [5 15]);
  
  result = [ 'OK     ' mfilename ];
