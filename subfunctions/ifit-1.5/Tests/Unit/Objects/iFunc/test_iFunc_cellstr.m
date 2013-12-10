function result=test_iFunc_cellstr

a=gauss;
a=cellstr(a);
if iscellstr(a)
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
