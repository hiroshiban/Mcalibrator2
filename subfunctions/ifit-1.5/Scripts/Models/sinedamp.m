function y=sinedamp(varargin)
% y = sinedamp(p, x, [y]) : Sine function. 
%
%   iFunc/sinedamp Damped Sine function. 
%     y  = p(4) + p(1)*sin((x - p(2))/p(3)).*exp(-x/p(5))
%
% input:  p: Sine model parameters (double)
%            p = [ Amplitude Phase_Shift Period BackGround Decay ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=sinedamp([1 0 1 1], -10:10); or plot(sinedamp);
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot, sine, expon

y.Name           = [ 'Damped-Sine function (1D) [' mfilename ']' ];
y.Parameters     = {'Amplitude','Phase_Shift','Period','Background','Decay'};
y.Dimension      = 1;
y.Description    = 'Damped Sine function';
y.Expression     = @(p,x) p(4) + p(1)*sin((x - p(2))/p(3)).*exp(-x/p(5));
y.Guess          =  @(x,y) [ max(y(:))-min(y(:)) mean(x(:)) std(x(:))/4 min(y(:)) std(x(:))*4 ];
y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end

