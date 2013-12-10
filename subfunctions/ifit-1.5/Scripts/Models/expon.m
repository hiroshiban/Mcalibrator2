function y=expon(varargin)
% y = expon(p, x, [y]) : Exponential decay
%
%   iFunc/expon Exponential decay fitting function
%     p(2)=Tau is the exponential decay parameter, in inverse 'x' units.
%     y=p(3)+p(1)*exp(-x/p(2));
%
% input:  p: Exponential decay model parameters (double)
%            p = [ Amplitude Tau BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=expon([1 0 1], -0:10); or plot(expon)
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot, twoexp, sinedamp

y.Name           = [ 'Exponential decay (1D) [' mfilename ']' ];
y.Description    = 'Exponential decay';
y.Parameters     = {'Amplitude','Tau decay in inverse "x" unit', 'Background'};
y.Expression     = @(p,x) p(3)+p(1)*exp(-x/p(2));
y.Dimension      = 1;         % dimensionality of input space (axes) and result
y.Guess          = @(x,y)[ ...
   exp(subsref(polyfit(x(:),log(y(:)-min(y(:))+0.01*abs(min(y(:)))),1), struct('type','()', 'subs',{{2}}))) ...
    -1/(subsref(polyfit(x(:),log(y(:)-min(y(:))+0.01*abs(min(y(:)))),1), struct('type','()', 'subs',{{1}}))-(abs(subsref(polyfit(x(:),log(y(:)-min(y(:))+0.01*abs(min(y(:)))),1), struct('type','()', 'subs',{{1}}))) < 1e-2)*.1) ...
    min(y(:)) ];
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end


