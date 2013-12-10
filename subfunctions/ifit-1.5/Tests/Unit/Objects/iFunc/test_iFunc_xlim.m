function result=test_iFunc_xlim

a= gauss;
b=xlim(a, 'Amplitude', [ 0 3 ]);
x=xlim(b, 'Amplitude');
if all(isnan(xlim(a,'Amplitude'))) && all(~isnan(x))
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
