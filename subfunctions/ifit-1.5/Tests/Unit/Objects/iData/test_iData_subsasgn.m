function result=test_iData_subsasgn

  a=iData(peaks);
  a{'alias'} = 20;
  a{0} = 2*a{0};
  a{1} = 2*a{1};
  a(10:20,:) = a(10:20,:)+100;
  
  if mean(a,0) > 20 && mean(a{1}) > 30
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
