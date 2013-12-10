function result=test_iData_waterfall

  h= waterfall(iData(peaks));
  
  if ~isempty(h)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
