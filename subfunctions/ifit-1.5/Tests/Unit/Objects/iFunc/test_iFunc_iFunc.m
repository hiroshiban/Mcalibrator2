function result=test_iFunc_iFunc

a=iFunc('x*p(1)+p(2)');
if ndims(a) == 1 && length(a.Parameters) == 2
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
