function result=test_iData_ylim

  a=iData(peaks);
  ylim(a);
  ylim(a, [5 15]);
  
  result = [ 'OK     ' mfilename ];
