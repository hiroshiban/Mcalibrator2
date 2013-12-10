function result=test_iData_ylabel

  a=iData(peaks);

  ylabel(a,'Y');
  
  if strcmp(ylabel(a), 'Y')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
