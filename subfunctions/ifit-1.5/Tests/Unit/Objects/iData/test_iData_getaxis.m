function result=test_iData_getaxis

  a=iData(peaks);
  
  if ~isempty(getaxis(a,1))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
