function result=test_Optimizers

  o = fits(iData); % get all Optimizers
  
  banana = @(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2; % Rosenbrock
  p = [];
  for index=1:length(o)
    [x,fval] = feval(o{index}, banana,[-1.2, 1]); % solution is x=[1 1]
    p = [ p ; x ];
  end
  
  if all(mean(abs(p)) > 0.5)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
