function result=test_iFunc_get

a=gauss;
b=get(a, 'Amplitude');
p=feval(a,'guess');
c=get(a, 'Amplitude');
e=get(a,'Expression');
if isempty(b) && isscalar(c) && c == a.Amplitude
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
