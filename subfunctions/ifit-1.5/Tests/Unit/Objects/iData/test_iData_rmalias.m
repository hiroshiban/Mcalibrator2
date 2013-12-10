function result=test_iData_rmalias

  a=iData(peaks);
  a.NewStuff='20';
  b=copyobj(a);
  rmalias(b, 'NewStuff');
  
  if ~isfield(b, 'NewStuff') && isfield(a, 'NewStuff')
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
