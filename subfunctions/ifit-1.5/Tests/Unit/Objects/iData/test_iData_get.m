function result=test_iData_get

  a=iData(peaks);
  
  if ~isempty(get(a,'Signal'))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
