function result = test_iData_load_vars

  a = iData(rand(10));
  b = iData(struct('a',1,'b','a string'));
  f = figure; peaks;
  d = iData(f);
  
  if all(~isempty([ a b d ]))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
