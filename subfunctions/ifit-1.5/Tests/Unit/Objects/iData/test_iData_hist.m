function result=test_iData_hist

  a=iData([ ifitpath 'Data/Monitor_GV*']); b=hist(a);
  
  if ndims(b) == 3
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
