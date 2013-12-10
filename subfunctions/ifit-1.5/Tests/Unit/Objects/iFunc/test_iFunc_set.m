function result=test_iFunc_set

a=gauss; feval(a);
b=get(a, 'Amplitude');
set(a,'Amplitude', 2);
c=get(a, 'Amplitude');
if c == 2
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
