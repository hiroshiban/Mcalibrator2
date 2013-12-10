function result=test_iData_iData

  p = peaks;
  a=iData(p);
  
  surf(p);
  b=iData(gcf);
  c=iData(b{1},b{2},b{0});
  
  s=struct(a);
  d=iData(s);
  e=iData(s.Data);
  f=iData({ p, s });
  g=iData([ a b ]);
  
  t = [ a b c d e f g ];
  
  % do they all match ?
  result = [ 'OK     ' mfilename ];
  for index = 1:length(t)
    if any(double(t(index)) ~= p)
      result = [ 'FAILED ' mfilename ];
    end
  end

