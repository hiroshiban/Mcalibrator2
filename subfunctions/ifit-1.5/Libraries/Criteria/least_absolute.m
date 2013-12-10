function c=least_absolute(Signal, Error, Model)
% c=least_absolute(Signal, Error, Model)
%
% weighted least absolute criteria
% the return value is a vector, and most optimizers use its sum (except LM).
% |Signal-Model|/Error
%
% A good fit corresponds with a criteria lower or equal to 1.
%
% <http://en.wikipedia.org/wiki/Least_absolute_deviation>
  if ~isnumeric(Signal) || ~isnumeric(Model), return; end
  if isempty(Error) || isscalar(Error) || all(Error == Error(end))
    index = find(isfinite(Model) & isfinite(Signal));
    c = abs(Signal(index)-Model(index)); % raw least absolute
  else
    index = find(isfinite(Error) & isfinite(Model) & isfinite(Signal));
    residuals  = Signal - Model;
    % make sure weight=1/sigma does not reach unrealistic values
    %   initially, most weights will be equal, but when fit impproves, 
    %   stdE will get lower, allowing better matching of initial weight.
    normE = sum(Error(index));
    stdE  = std(residuals(index));
    Error( Error < stdE ) = stdE; 
    Error = Error *(normE/sum(Error(index)));
    
    if isempty(index), c=Inf;
    else               c=abs((residuals(index))./Error(index));
    end
  end
end % least_absolute
