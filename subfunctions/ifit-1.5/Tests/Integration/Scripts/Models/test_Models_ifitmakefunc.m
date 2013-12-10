function result = test_Models_ifitmakefunc

  % create a new data set and convert it to an iData
  x = linspace(0,2*pi, 100);
  p = [1 0.3 .1 2 0.5];
  y = p(1)*sin((x-p(2))/p(3)).*exp(-x/p(4))+p(5);
  % add noise
  y = y+p(1)*0.01*randn(size(y));
  a = iData(x,y); a.Error=0;
  % create the corresponding function
  sinexp = ifitmakefunc('sinexp','Exponentially decreasing sine', ...
    'Amplitude Centre Period Width Background', ...
    'p(1)*sin((x-p(2))/p(3)).*exp(-x/p(4))+p(5)','automatic');
  % perform the fit
  [p1, e, m, o]=fits(a,sinexp,[1.15 0.4 0.15 1.7 0.2],'fminralg');
  plot(a, o.modelValue);
  
  if all(abs(abs(p1(:))-p(:)) < 0.4)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
