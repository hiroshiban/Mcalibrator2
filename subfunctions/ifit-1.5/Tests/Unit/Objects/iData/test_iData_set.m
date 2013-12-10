function result=test_iData_set

  a=iData(peaks);
  set(a,'NewStuff',20);
  set(a,'Signal', a{0}*2);
  
  if isfield(a, 'NewStuff') 
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
