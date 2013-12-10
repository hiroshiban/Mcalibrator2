function result=test_iData_rotate

  a=iData(gauss);
  b=rotate(a);
  
  if ndims(b) == 2
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
