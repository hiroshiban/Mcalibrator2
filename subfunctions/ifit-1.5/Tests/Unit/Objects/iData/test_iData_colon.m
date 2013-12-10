function result=test_iData_colon
  
  a = iData(peaks);
  b=a:(cos(a)+5);
  
  if length(b) == 6
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
