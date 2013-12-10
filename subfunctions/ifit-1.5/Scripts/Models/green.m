function y=green(varargin)
% y = green(p, x, [y]) : Green function
%
%   iFunc/green Green fitting function
%     y = (p(1)*p(3)*p(2)^2 ) ./ ( (p(2)^2 - x.^2).^2 + (x*p(3)).^2) + p(4);
%
% input:  p: Green model parameters (double)
%            p = [ Amplitude Center HalfWidth BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=green([1 0 1 1], -10:10); or plot(green);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

y.Name      = [ 'Green function (1D) [' mfilename ']' ];
y.Parameters={'Amplitude','Centre','HalfWidth','Background'};
y.Description='Green function model';
y.Expression= @(p,x) (p(1)*p(3)*p(2)^2 ) ./ ( (p(2)^2 - x.^2).^2 + (x*p(3)).^2) + p(4);
% moments of distributions
m1 = @(x,s) sum(s(:).*x(:))/sum(s(:));
m2 = @(x,s) sqrt(abs( sum(x(:).*x(:).*s(:))/sum(s(:)) - m1(x,s).^2 ));

y.Guess     = @(x,s) [ NaN m1(x, s-min(s(:))) m2(x, s-min(s(:))) NaN ];

y = iFunc(y);


if length(varargin)
  y = y(varargin{:});
end


