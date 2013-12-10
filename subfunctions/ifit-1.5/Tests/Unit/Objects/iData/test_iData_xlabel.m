function result=test_iData_xlabel

  a=iData(peaks);

  xlabel(a,'X');
  
  if strcmp(xlabel(a), 'X')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
