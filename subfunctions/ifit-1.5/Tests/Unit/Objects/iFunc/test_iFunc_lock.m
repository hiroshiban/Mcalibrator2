function result=test_iFunc_lock

a=gauss;
b=mlock(a, 'Amplitude');
c=munlock(b,'Amplitude');
if all([ mlock(a) mlock(b) mlock(c) ] == [ 0 1 0 ])
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
