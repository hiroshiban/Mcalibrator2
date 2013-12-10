function result=test_iFunc_subplot

a= [ iFunc('x*p(1)+p(2)') gauss lorz2d ];
h = subplot(a);
if length(h) == length(a)
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
