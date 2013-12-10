function result = test_iData_permute

  a = iData([ ifitpath 'Data/Diff_BananaPSD_1314088587.th_y' ]);
  b = permute(a, [ 2 1 ]);
  
  if all(size(b) == size(a, [ 2 1]))
    result = 1;
  else
    result = 0;
  end
