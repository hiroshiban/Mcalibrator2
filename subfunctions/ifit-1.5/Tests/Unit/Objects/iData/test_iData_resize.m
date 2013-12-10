function result = test_iData_resize

  a = iData([ ifitpath 'Data/Diff_BananaPSD_1314088587.th_y' ]);
  sz = size(a)*2;
  b = resize(a, sz);
  
  if all(size(b) == sz)
    result = 1;
  else
    result = 0;
  end
