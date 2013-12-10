function result=test_iData_isvector
  
  a=iData(peaks);
  b=iData(1:20);
  c=iData([ ifitpath 'Data/Monitor_GV*']); 
  
  if ~isvector(a) && isvector(b) == 1 && isvector(c) > 1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
