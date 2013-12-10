function result=test_iFunc_isempty

a=iFunc('x*p(1)+p(2)');
if ~isempty(a) == 1 && isempty(iFunc)
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
