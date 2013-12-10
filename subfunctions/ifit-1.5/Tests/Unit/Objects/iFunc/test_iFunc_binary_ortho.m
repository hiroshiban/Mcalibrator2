function result = test_iFunc_binary_ortho

% operator may be: 'mtimes','mrdivide','mpower' -> perform orthogonal axes dimensionality extension

  op = {'mtimes','mrdivide','mpower'};
  
  a = gauss;
  b = lorz;
  
  result = [ 'OK     ' mfilename ' (' num2str(length(op)) ' operators)' ];
  failed = '';
  
  for index=1:length(op)
    % perform op on iFunc
    c  = feval(op{index}, a, b);
    
    % we just check that resulting object has dimension a+b
    if ndims(a)+ndims(b) ~= ndims(c)
      failed = [ failed ' ' op{index} ];
    end
  end
  if length(failed)
    result = [ 'FAILED ' mfilename ' ' failed ];
  end
  
  
