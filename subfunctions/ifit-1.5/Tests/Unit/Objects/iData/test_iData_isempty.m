function result=test_iData_isempty

  a=iData(peaks);
  a.Data.Signal=[];
  
  if isempty(a)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
