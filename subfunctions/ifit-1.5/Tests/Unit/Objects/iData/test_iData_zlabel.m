function result=test_iData_zlabel

  a=iData(flow);

  zlabel(a,'Z');
  
  if strcmp(zlabel(a), 'Z')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
