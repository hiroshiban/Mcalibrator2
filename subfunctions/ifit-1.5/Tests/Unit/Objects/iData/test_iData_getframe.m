function result=test_iData_getframe

  a=iData(peaks);
  
  if isstruct(getframe(a))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
