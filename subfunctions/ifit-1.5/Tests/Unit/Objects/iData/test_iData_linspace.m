function result=test_iData_linspace

  a = iData(peaks);
  b=linspace(a,cos(a)+10,9);
  
  if length(b) == 9
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
