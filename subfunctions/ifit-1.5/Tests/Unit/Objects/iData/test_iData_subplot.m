function result=test_iData_subplot

  h= subplot([ iData(1:100) iData(peaks) iData(flow) ]);
  
  if numel(h) == 3
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
