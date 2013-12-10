function y=lorz(varargin)
% y = lorz(p, x, [y]) : Lorentzian
%
%   iFunc/lorz Lorentzian fitting function
%     y = p(1) ./ (1+ ((x-p(2)).^2/p(3)^2) ) + p(4);
%
% input:  p: Lorentzian model parameters (double)
%            p = [ Amplitude Centre HalfWidth BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=lorz([1 0 1 1], -10:10); or plot(lorz)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

y.Name       = [ 'Lorentzian (1D) [' mfilename ']' ];
y.Parameters = {'Amplitude','Centre','HalfWidth','Background'};
y.Description= 'Single 1D Lorentzian model';
y.Expression = @(p,x) p(1) ./ (1+ ((x-p(2)).^2/p(3)^2) ) + p(4);

% moments of distributions
m1 = @(x,s) sum(s(:).*x(:))/sum(s(:));
m2 = @(x,s) sqrt(abs( sum(x(:).*x(:).*s(:))/sum(s(:)) - m1(x,s).^2 ));

y.Guess     = @(x,s) [ NaN m1(x, s-min(s(:))) m2(x, s-min(s(:))) NaN ];

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end
