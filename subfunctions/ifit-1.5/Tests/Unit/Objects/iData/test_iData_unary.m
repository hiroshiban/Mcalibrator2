function result = test_iData_unary

  op = {'abs','acosh','acos','asinh','asin','atanh','atan','ceil','conj','cosh','cos', ...
    'ctranspose','del2','exp','fliplr','flipud','floor','full','imag','isfinite', ...
    'isfloat','isinf','isinteger','islogical','isnan','isnumeric','isreal','isscalar', ...
    'issparse','log10','log','norm','not','permute','real','round','sign','sinh','sin', ...
    'sparse','sqrt','tanh','tan','transpose','uminus','uplus', ...
    'cumtrapz','sum','prod','trapz','cumsum','cumprod',...
    'gradient','min','mean','median','sort','squeeze',...
    'double','logical','single','sqr'};
  
  a = iData([ ifitpath 'Data/ILL_IN6.dat' ]);
  d = double(a);
  result = [ 'OK     ' mfilename ' (' num2str(length(op)) ' operators)' ];
  failed = '';
  for index=1:length(op)
    
    % operator on iData
    try
      d1 = feval(op{index}, a);
    catch
      failed = [ failed ' ' upper(op{index}) ];
    end
    
    % operator on double(iData) and special cases
    % del2(iData) returns del2*2*ndims(a)
    switch op{index}
    case 'del2'
      d1 = d1/2/ndims(a); d2 = feval(op{index}, d);
    case 'gradient' % select 1-rank
      d1 = d1(2);         d2 = feval(op{index}, d);
    case 'sqr'
      d2 = d2 .* d2;
    case 'permute'
      d2 = feval(op{index}, d, [2 1]);
    otherwise
      d2 = feval(op{index}, d);
    end
    d1 = double(d1);
    
    % do they match ?
    if (abs(sum(d1(:)) - sum(d2(:))))/(abs(sum(d1(:)) + sum(d2(:)))) > 0.01
      fprintf(1, '%s:%s: %g ~= %g\n', mfilename, op{index}, abs(sum(d1(:))), abs(sum(d2(:))));
      failed = [ failed ' ' op{index} ];
    end
  end
  if length(failed)
    result = [ 'FAILED ' failed ];
  end
  
  
