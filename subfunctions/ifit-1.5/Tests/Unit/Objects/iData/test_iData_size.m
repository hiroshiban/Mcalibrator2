function result=test_iData_size

  a=iData(peaks);
  s=getaxis(a,0);
  if all(size(a) == size(s))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
