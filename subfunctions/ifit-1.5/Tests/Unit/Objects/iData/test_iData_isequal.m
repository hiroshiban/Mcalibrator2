function result=test_iData_union

  a=iData(peaks); b=copyobj(a);
  
  if isequal(a,b) && ~isequal(a, cos(a))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
