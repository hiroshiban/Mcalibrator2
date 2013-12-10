function result=test_iData_zlim

  a=iData(flow);
  zlim(a);
  zlim(a, [5 15]);
  
  result = [ 'OK     ' mfilename ];
