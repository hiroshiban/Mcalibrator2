function result=test_iData_logspace
  
  a = iData(peaks);
  b=logspace(a,cos(a)+10,9);
  
  if length(b) == 9
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
