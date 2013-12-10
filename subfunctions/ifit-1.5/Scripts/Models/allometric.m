function y=allometric(varargin)
% y = allometric(p, x, [y]) : Power/Freundlich/Belehradek function
%
%   iFunc/allometric Power/Freundlich/Belehradek fitting function
%                    to describe power and asymptotic laws
%     y = p(1)*(x-p(2)).^p(3) + p(4);
%
% Reference: Ratkowksy, David A. 1990. Handbook of Nonlinear Regression Models. Marcel Dekker, Inc. 4.3.1 
%
% input:  p: Power model parameters (double)
%            p = [ Amplitude Offset Exponent BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=allometric([1 0 1 1], -10:10); or plot(allometric)
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/plot

y.Name      = [ 'Allometric/Freundlich (1D) [' mfilename ']' ];
y.Description='Power/Freundlich/Belehradek fitting function to describe power and asymptotic laws. Ref: Ratkowksy, David A. 1990. Handbook of Nonlinear Regression Models. Marcel Dekker, Inc. 4.3.1 ';
y.Parameters= {'Amplitude','Offset','Exponent','Background'};
y.Expression= @(p,x) p(1)*(x-p(2)).^p(3) + p(4); 
y.Guess     = @(x,signal) [ max(signal(:))-min(signal(:)) min(x(:))-mean(x(:))/10 .1 min(signal(:)) ];
 
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end
