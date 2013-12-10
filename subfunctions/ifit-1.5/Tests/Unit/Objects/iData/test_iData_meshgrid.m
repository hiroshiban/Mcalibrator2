function result=test_iData_meshgrid

  a=iData([ ifitpath 'Data/Monitor_GV*']);
  b=meshgrid(a);
  
  if ndims(b) == 3
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
