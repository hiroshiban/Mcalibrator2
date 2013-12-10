function iData_private_error(a,b)
% for compatibility with Matlab < 6.5
if nargin == 1
  b=a;
  a='iData';
end
b = [ 'iData/' a ': ' b ];
a = [ 'iData:' a ];
try
  error(a,sprintf(b));
catch
  error(sprintf(b));
end
