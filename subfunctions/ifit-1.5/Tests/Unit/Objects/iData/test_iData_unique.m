function result=test_iData_unique

  a=iData(peaks);
  x=a{1};
  x(2)=x(1);
  a{1} = x;
  
  b=unique(a);
  
  if size(b,1) == size(a,1)-1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
