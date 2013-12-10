function result = test_iData_gradient

  a=iData(peaks);
  g=gradient(a); 
  if length(g) == 2, 
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
