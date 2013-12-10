function c=least_median(Signal, Error, Model)
% c=least_median(Signal, Error, Model)
%
% weighted median absolute criteria
% the return value is a scalar
% median(|Signal-Model|/Error)
%
% A good fit corresponds with a criteria lower or equal to 1.
%
% <http://en.wikipedia.org/wiki/Median_absolute_deviation>
  c = median(least_absolute(Signal, Error, Model));
end % least_median
