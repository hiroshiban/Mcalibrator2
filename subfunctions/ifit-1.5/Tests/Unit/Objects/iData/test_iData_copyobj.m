function result=test_iData_copyobj

a=iData(peaks);  
b=copyobj(a);
  
  if isequal(a,b)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end

