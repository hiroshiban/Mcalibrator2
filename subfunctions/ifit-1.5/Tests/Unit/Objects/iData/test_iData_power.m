function result=test_iData_power

  a=iData(peaks);
  b=a.^2;
  a=a{0}; a=a.^2;
  b=b{0};
  
  if all(abs(a(:) - b(:)) < 1e-3)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
