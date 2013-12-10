function result=test_iData_getalias

  a=iData(peaks);
  
  if ~isempty(getalias(a,'Signal'))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
