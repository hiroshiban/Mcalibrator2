function result=test_iFunc_char

a=gauss;
a=char(a);
if char(a)
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
