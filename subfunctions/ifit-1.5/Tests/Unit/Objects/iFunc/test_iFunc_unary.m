function result = test_iFunc_unary

% Supported operations:
% abs acosh acos asinh asin atanh atan ceil conj cosh cos ctranspose del2 exp 
% find fliplr flipud floor full imag isfinite isfloat isinf isinteger islogical 
% isnan isnumeric isreal isscalar issparse log10 logical log norm not 
% real round sign single sinh sin sparse sqrt tanh tan transpose uminus uplus 
% single double find logical

  op = textscan([ ...
  'abs acosh acos asinh asin atanh atan ceil conj cosh cos ctranspose del2 exp ' ...
  'fliplr flipud floor full imag ' ...
  'log10 log norm not  ' ...
  'real round sign sinh sin sparse sqrt tanh tan transpose uminus uplus  '],'%s'); op=op{1};
  
  p = [ 4 3 2 1 ]; p=p.*(1+.05*rand(1,4));
  x = linspace(-10,10,100);
  
  a = gauss;
  result = [ 'OK     ' mfilename ' (' num2str(length(op)) ' operators)' ];
  failed = '';
  
  d2 = feval(a, p, x);
  
  for index=1:length(op)
    
    % operator on iData
    try
      d1 = feval(op{index}, a);
      % evaluate resulting function on axis
      d1 = feval(d1, p, x);
    catch
      failed = [ failed ' ' upper(op{index}) ]; d1=[];
    end
    
    
    
    % do they match ?
    if (abs(sum(d1(:)) - sum(d2(:))))/(abs(sum(d1(:)) + sum(d2(:)))) > 0.01
      fprintf(1, '%s:%s: %g ~= %g\n', mfilename, op{index}, abs(sum(d1(:))), abs(sum(d2(:))));
      failed = [ failed ' ' op{index} ];
    end
  end
  if length(failed)
    result = [ 'FAILED ' failed ];
  end
  
  
