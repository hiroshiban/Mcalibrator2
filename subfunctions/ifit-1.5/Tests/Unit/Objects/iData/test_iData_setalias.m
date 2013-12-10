function result=test_iData_setalias

  a=iData(peaks);
  setalias(a,'NewStuff',20);
  setalias(a,'Signal', 'Data.Signal');
  setalias(a,'Signal', 'this.Data.Signal*2');
  
  if isfield(a, 'NewStuff') 
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
