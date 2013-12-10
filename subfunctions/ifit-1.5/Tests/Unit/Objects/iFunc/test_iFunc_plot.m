function result=test_iFunc_plot

a=iFunc('x*p(1)+p(2)'); b=gauss;
h = plot(a,b);
if length(h) == 2
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
