function result=test_iData_commandhistory

  a=iData(flow);
  b=commandhistory(a);
  
  if iscell(b)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
  
