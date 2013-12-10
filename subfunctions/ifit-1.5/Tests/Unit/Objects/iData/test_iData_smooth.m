function result = test_iData_smooth

  a = iData([ ifitpath 'Data/Diff_BananaPSD_1314088587.th_y' ]);
  a = a.*(1+0.1*randn(size(a)));
  b = smooth(a);
  c = smooth(a, 'sgolay','',1);
  
  if std(std(double(a-b))) < 0.03 && std(std(double(a-c))) < 0.5
    result = 1;
  else
    result = 0;
  end
