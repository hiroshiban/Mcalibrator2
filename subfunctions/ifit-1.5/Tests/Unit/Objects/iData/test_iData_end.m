function result=test_iData_end

  a = iData(peaks);
  
  b = zeros(iData, 2,3);
  b(end)=a;
  c = b(end);
  d=a{0};
  
  if isequal(a,c) && double(c(end)) == d(end)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
