function result=test_iData_findobj

  a = iData(peaks);
  b = iData([ ifitpath 'Data/insulin_pilatus6mconverted_orig.cbf' ]);
  
  if numel(findobj(iData,'Title','insuli')) == 1 && numel(findobj(iData)) == 2
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
  
