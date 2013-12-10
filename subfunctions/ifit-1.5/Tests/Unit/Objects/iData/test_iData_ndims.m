function result=test_iData_ndims

  a=iData(peaks);
  b=iData(1:10);
  
  if ndims(a) == 2 && ndims(b) == 1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
