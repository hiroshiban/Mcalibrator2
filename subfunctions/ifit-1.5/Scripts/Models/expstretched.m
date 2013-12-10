function y=expstretched(varargin)
% y = expstretched(p, x, [y]) : Exponential decay
%
%   iFunc/expstretched Stretched exponential decay fitting function
%     Tau is the expeonential decay parameter, in inverse 'x' units.
%     y=p(4)+p(1)*exp(-(x/p(2)).^p(3));
%
% input:  p: Stretched exponential decay model parameters (double)
%            p = [ Amplitude Tau Exponent BackGround ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=expstretched([1 0 1 1], -10:10); or plot(expstretched)
%
%         I will not buy this exponential; it is stretched.
%         <http://en.wikipedia.org/wiki/Dirty_Hungarian_Phrasebook>
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot


y.Name           = [ 'Stretched Exponential decay (1D) [' mfilename ']' ];
y.Description    = 'Stretched Exponential decay';
y.Parameters     = {'Amplitude','Tau decay in inverse "x" unit', 'Exponent', 'Background'};
y.Expression     = @(p,x) p(4)+p(1)*exp(-(x/p(2)).^p(3));
y.Dimension      = 1;         % dimensionality of input space (axes) and result
y.Guess          = @(x,y)[ ...
   exp(subsref(polyfit(x(:),log(y(:)-min(y(:))+0.01*abs(min(y(:)))),1), struct('type','()', 'subs',{{2}}))) ...
    -1/(subsref(polyfit(x(:),log(y(:)-min(y(:))+0.01*abs(min(y(:)))),1), struct('type','()', 'subs',{{1}}))-(abs(subsref(polyfit(x(:),log(y(:)-min(y(:))+0.01*abs(min(y(:)))),1), struct('type','()', 'subs',{{1}}))) < 1e-2)*.1) ...
    1 min(y(:)) ];
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

