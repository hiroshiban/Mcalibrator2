function result=test_iData_conv

  a=iData(gauss);
  b=convn(a,a);
  c=convn(a,std(a));
  if abs(std(b)-std(c)) < 0.1
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
