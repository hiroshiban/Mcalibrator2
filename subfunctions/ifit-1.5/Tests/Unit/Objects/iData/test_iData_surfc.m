function result=test_iData_surfc

  h= surfc(iData(peaks));
  
  if ~isempty(h)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
