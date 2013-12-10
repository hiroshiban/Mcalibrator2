function result = test_iFunc_binary

% operator may be: 'plus','minus','times','rdivide','conv', 'xcorr', 'power'
%                  'mtimes','mrdivide','mpower' -> perform orthogonal axes dimensionality extension

  op = {'plus','minus','times','rdivide','conv', 'xcorr', 'power'};
  
  a = gauss;
  b = lorz;
  
  result = [ 'OK     ' mfilename ' (' num2str(length(op)) ' operators)' ];
  failed = '';
  
  for index=1:length(op)
    % perform op on iFunc
    c  = feval(op{index}, a, b);
    d1 = feval(c); % evaluate function
    
    % perform op on feval(iFunc)
    switch op{index}
    case 'xcorr'
      d2 = fxcorr(feval(a), feval(b));
    otherwise
      d2 = feval(op{index}, feval(a), feval(b));
    end
    
    % test if they match
    if (abs(sum(d1(:))) - abs(sum(d2(:))))/(abs(sum(d1(:))) + abs(sum(d2(:)))) > 0.01
      fprintf(1, '%s:%s: %g ~= %g\n', mfilename, op{index}, abs(sum(d1(:))), abs(sum(d2(:))));
      failed = [ failed ' ' op{index} ];
    end
  end
  if length(failed)
    result = [ 'FAILED ' mfilename ' ' failed ];
  end
  
  
