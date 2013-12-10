function result = test_iData_reshape

  a = iData([ ifitpath 'Data/Diff_BananaPSD_1314088587.th_y' ]);
  sz = size(a).* [ 2 0.5 ];
  b = reshape(a, sz);
  
  if all(size(b) == sz)
    result = 1;
  else
    result = 0;
  end
