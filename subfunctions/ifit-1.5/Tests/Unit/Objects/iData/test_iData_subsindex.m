function result=test_iData_subsindex

  a=iData(1:10);
  b=1:100;
  c=b(a);
  
  if all(c == b(1:10))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
