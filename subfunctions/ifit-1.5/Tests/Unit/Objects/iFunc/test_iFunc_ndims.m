function result=test_iFunc_ndims

a=iFunc('x*p(1)+p(2)');
if ndims(a) == 1 && ndims(iFunc) == 0
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
