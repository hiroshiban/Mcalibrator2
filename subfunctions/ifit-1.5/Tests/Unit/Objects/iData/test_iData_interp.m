function result=test_iData_interp

  a=iData(peaks); 
  b=interp(a, 'grid'); 
  c=interp(a, 2);
  
  d = interp(a,1:.25:15,3:.25:12);
  
  if all(size(a)*2 == size(c)) ...
    && all(size(d) == [ length(1:.25:15) length(3:.25:12) ])
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
