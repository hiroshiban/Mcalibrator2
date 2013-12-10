function y=pareto(varargin)
% y = pareto(p, x, [y]) : Pareto distribution function. 
%
%   iFunc/pareto Pareto distribution function. 
%     y  = p(4)+ p(1)*(p(3)./x).^p(2);
%
% Reference: http://en.wikipedia.org/wiki/Pareto_distribution
%
% input:  p: Pareto model parameters (double)
%            p = [ Amplitude Exponent Width BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=pareto([1 0 1 1], -10:10); or plot(pareto);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

y.Name      = [ 'Pareto distribution distribution function (1D) [' mfilename ']' ];
y.Parameters={'Amplitude','Exponent','Width','Background'};
y.Description='Pareto distribution distribution function. http://en.wikipedia.org/wiki/Pareto_distribution';
y.Expression= @(p,x) p(4)+ p(1)*(p(3)./abs(x)).^p(2);
y.Guess     = @(x,y) [ (max(y(:))-min(y(:)))/2 mean(abs(x(:))) std(x(:)) min(y(:)) ];

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end


