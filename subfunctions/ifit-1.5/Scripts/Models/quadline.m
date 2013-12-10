function y=quadline(varargin)
% y = quadline(p, x, [y]) : Quadratic line
%
%   iFunc/quadline Quadratic fitting function
%     y=p(3)+p(2)*x+p(1)*x.*x;
%
% Reference: http://en.wikipedia.org/wiki/Quadratic_function
%
% input:  p: Quadratic line model parameters (double)
%            p = [ Quadratic Linear Constant ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=quadline([1 0 1], -10:10); or y=quadline('identify') or p=quadline('guess',x,y);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot, strline, quad2d

y.Name      = [ 'Quadratic equation (1D) [' mfilename ']' ];
y.Parameters={'Quadratic' 'Linear','Constant'};
y.Description='Quadratic equation. Ref: http://en.wikipedia.org/wiki/Quadratic_function';
y.Expression= @(p,x) p(3)+p(2)*x+p(1)*x.*x;
y.Guess     = @(x,y) [ polyfit(x(:), y(:), 2) ];

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

