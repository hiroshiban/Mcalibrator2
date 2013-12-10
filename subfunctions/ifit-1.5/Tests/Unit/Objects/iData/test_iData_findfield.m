function result=test_iData_findfield

  a=iData([ ifitpath 'Data/insulin_pilatus6mconverted_orig.cbf' ]);
  
  if length(findfield(a)) > 10 && length(findfield(a, 'Detector','exact')) == 1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
