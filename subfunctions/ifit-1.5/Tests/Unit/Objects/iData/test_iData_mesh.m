function result=test_iData_mesh

  h= mesh(iData(peaks));
  
  if ~isempty(h)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
