function c=max_corrcoef(Signal, Error, Model)
% c=max_corrcoef(Signal, Error, Model)
%
% maximum correlation coefficient 
% the return value is 1-corrcoef(Signal, Model) with non diagonal term of the 
% correlation matrix. This value lies within [0 2]. When 0, it is a perfect match.
% This criteria does not use the error bars.
%
% <http://en.wikipedia.org/wiki/Correlation_coefficient>

  index = find(isfinite(Model) & isfinite(Signal));
  c = corrcoef(Signal(index),Model(index));
  c = 1 - c(1,2); % non diag is in [-1 1]

end % max_corrcoef
