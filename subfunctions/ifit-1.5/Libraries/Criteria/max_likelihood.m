function c=max_likelihood(Signal, Error, Model)
% c=max_likelihood(Signal, Error, Model)
%
% Maximum-likelihood criteria, which minimizes the Normal log-likelihood
% the return value is a vector, and most optimizers use its sum (except LM).
% (|Signal-Model|/sigma).^2 + 1/2 log(2pi sigma)
%
% A good fit corresponds with a criteria lower or equal to 1.
%
% <http://en.wikipedia.org/wiki/Maximum_likelihood>

  index = find(isfinite(Error) & isfinite(Model) & isfinite(Signal));
  residuals  = Signal - Model;
    
  if isempty(Error) || isscalar(Error) || all(Error == Error(end))
    sigma2 = std(Signal-Model).*ones(size(Signal));
  else
    % make sure weight=1/sigma does not reach unrealistic values
    %   initially, most weights will be equal, but when fit impproves, 
    %   stdE will get lower, allowing better matching of initial weight.
    normE = sum(Error(index));
    stdE  = std(residuals(index));
    Error( Error < stdE ) = stdE; 
    Error = Error *(normE/sum(Error(index)));
    sigma2 = Error.^2;
  end
  
  % compute likelihood
  c      = ( sum(residuals(index).^2./sigma2(index)+log(2*pi*sigma2(index))) )/2; % log(L)
end % max_likelihood
