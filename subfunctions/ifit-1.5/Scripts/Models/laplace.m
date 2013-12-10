function y=laplace(varargin)
% y = laplace(p, x, [y]) : Laplace distribution function. 
%
%   iFunc/laplace Laplace distribution function. 
%     y  = p(4)+ p(1)/2/p(3) .* exp( abs(x - p(2))/p(3) );
%
% input:  p: Laplace model parameters (double)
%            p = [ Amplitude Center Width BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=laplace([1 0 1 1], -10:10); or plot(laplace);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

y.Name      = [ 'Laplace distribution function (1D) [' mfilename ']' ];
y.Parameters={'Amplitude','Centre','Width','Background'};
y.Description='Laplace distribution function';
y.Expression= @(p,x) p(4)+ p(1)/2/p(3) .* exp( - abs(x - p(2))/p(3) );
y.Guess     = @(x,y) [ (max(y(:))-min(y(:)))/2 mean(x(:)) std(x(:)) min(y(:)) ];

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

