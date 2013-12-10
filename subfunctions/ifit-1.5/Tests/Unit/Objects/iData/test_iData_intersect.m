function result=test_iData_intersect

  a=iData(peaks); b=copyobj(a);
  b{1} = b{1} + 10;
  b{2} = b{2} - 10;
  c = intersect(a,b);
  
  if all(size(c) == size(a)-10)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
