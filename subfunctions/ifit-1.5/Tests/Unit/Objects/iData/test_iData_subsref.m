function result=test_iData_subsref

  a=iData(peaks);
  s=a.Signal;
  s=a{0};
  s=a(1:10,:);
  s=a(1:10);
  
  if all(size(a.Signal) == size(a{0})) && size(a(1:10,:), 1) == size(a(1:10),2)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
