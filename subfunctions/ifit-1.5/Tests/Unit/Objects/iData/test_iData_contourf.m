function result=test_iData_contourf

  h= contourf(iData(peaks));
  
  if ~isempty(h)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
