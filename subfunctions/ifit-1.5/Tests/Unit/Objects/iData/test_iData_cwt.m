function result = test_iData_cwt

  a = iData([ ifitpath 'Data/Diff_BananaTheta_1314088587.th' ]);
  b = cwt(a, 'plot');

  result = 1;
