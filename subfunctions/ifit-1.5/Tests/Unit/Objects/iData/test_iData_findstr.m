function result=test_iData_findstr

  a = iData([ ifitpath 'Data/insulin_pilatus6mconverted_orig.cbf' ]);
  
  if numel(findstr(a,'Pilatus6M')) >= 1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
