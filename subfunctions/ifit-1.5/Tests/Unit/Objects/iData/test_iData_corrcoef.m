function result=test_iData_corrcoef

a = load(iData, [ ifitpath 'Data/sv1850.scn']);
m = gauss;
[p,dummy,dummy,o] = fits(a,m, '', 'fminpowell');
c = corrcoef(a,m);

if abs(c(1,2) - o.corrcoef ) < 0.005
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
