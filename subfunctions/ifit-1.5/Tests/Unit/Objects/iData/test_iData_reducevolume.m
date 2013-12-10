function result=test_iData_reducevolume

  a=iData(rand(2000,2000));
  b=reducevolume(a);
  
  if prod(size(b)) < prod(size(a))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
