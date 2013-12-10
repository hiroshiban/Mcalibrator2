function y=dirac(varargin)
% y = dirac(p, x, [y]) : Dirac
%
%   iFunc/dirac Dirac fitting function
%      y(x==p(2)) = p(1)
%   The function called with a char argument performs specific actions.
%   You may create new fit functions with the 'ifitmakefunc' tool.
%
% input:  p: Dirac model parameters (double)
%            p = [ Amplitude Centre ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=dirac([1 0 1 1], -10:10); or plot(dirac)
%
% Version: $Revision: 1070 $
% See also iData, iFunc/fits, iFunc/plot

y.Name       = [ 'Dirac (1D) [' mfilename ']' ];
y.Description='Dirac peak fitting function';
y.Parameters = {'Amplitude','Centre'};
y.Expression = @(p,x) p(1)*(abs(x - p(2)) == min(abs(x(:) - p(2))));
y.Dimension  = 1;
% moments of distributions
m1 = @(x,s) sum(s(:).*x(:))/sum(s(:));

y.Guess      = @(x,signal) [ NaN m1(x, signal-min(signal(:))) ];

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end


