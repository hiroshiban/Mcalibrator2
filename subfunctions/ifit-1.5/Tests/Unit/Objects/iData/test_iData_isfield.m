function result=test_iData_isfield

  a=iData(peaks);
  
  if isfield(a, 'Signal') && isfield(a, 'Data')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
