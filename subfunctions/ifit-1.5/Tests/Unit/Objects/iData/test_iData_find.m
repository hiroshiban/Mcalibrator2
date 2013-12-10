function result=test_iData_find

  a = iData(peaks);
  
  b = a(20,20);
  
  c = (a == b.Signal);
  
  if find(a.Signal == double(a(20,20))) == find(a == double(a(20,20)))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
