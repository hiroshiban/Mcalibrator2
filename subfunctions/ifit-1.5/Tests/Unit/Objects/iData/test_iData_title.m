function result=test_iData_title

  a=iData(peaks);
  t='toto';
  title(a,t);
  
  if strcmp(title(a), t)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
