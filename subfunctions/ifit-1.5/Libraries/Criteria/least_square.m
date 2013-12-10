function c=least_square(Signal, Error, Model)
% c=least_square(Signal, Error, Model)
%
% weighted least square criteria, which is also the Chi square
% the return value is a vector, and most optimizers use its sum (except LM).
% (|Signal-Model|/Error).^2
%
% A good fit corresponds with a criteria lower or equal to 1.
%
% <http://en.wikipedia.org/wiki/Least_squares>
  c = least_absolute(Signal, Error, Model);
  c = c.*c;
end % least_square
