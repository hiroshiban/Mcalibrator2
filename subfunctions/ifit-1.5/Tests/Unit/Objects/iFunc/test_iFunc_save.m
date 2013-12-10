function result=test_iFunc_save

a=iFunc('x*p(1)+p(2)'); 
h = save(a);
if ischar(h)
  result = [ 'OK     ' mfilename ];
  delete(h)
else
  result = [ 'FAILED ' mfilename ];
end
