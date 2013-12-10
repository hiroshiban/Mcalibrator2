function result = test_iData_binary

  op = {'combine','conv','convn','eq','ge','gt','le','lt','minus', ...
  'mrdivide','ne','plus','power','rdivide','times','xcorr'};
  
  a = iData([ ifitpath 'Data/ILL_IN6.dat' ]);    a.Monitor=1;
  b = iData([ ifitpath 'Data/ILL_IN6_2.dat' ]);  b.Monitor=2;
  da=get(a,'Signal'); db=get(b,'Signal');
  result = [ 'OK     ' mfilename ' (' num2str(length(op)) ' operators)' ];
  failed = '';
  for index=1:length(op)
    % operator on double(iData)
    switch op{index}
    case 'conv'
      d2 = feval('fconv', da, db, 'same'); 
    case 'convn'
      d2 = feval('fconv', da, db, 'same pad background center normalize');
    case 'xcorr'
      d2 = feval('fconv', da, db, 'same correlation');
    case 'combine'
      d2 = (da+db)/(a.Monitor+b.Monitor);
    case {'mpower','mtimes'}
      d2 = 0;
    otherwise
      d2 = feval(op{index}, da/a.Monitor, db/b.Monitor);
    end
    
    % operator on iData
    try
      d1 = feval(op{index}, a, b);
    catch
      failed = [ failed ' ' upper(op{index}) ];
    end
    d1 = double(d1);
    
    % do they match ?
    if (abs(sum(d1(:))) - abs(sum(d2(:))))/(abs(sum(d1(:))) + abs(sum(d2(:)))) > 0.01
      fprintf(1, '%s:%s: %g ~= %g\n', mfilename, op{index}, abs(sum(d1(:))), abs(sum(d2(:))));
      failed = [ failed ' ' op{index} ];
    end
  end
  if length(failed)
    result = [ 'FAILED ' mfilename ' ' failed ];
  end
  
  
