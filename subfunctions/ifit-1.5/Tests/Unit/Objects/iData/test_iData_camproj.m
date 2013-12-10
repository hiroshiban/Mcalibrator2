function result=test_iData_camproj

  a=iData(peaks); 
  b=[ camproj(a) sum(a) prod(a) cumsum(a) cumprod(a) ];
  
  if length(b) == 5
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
