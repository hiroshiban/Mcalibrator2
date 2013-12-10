function result=test_iData_char

  a=iData(peaks);
  b=char(a);
  if ischar(b)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
