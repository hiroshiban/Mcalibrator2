function y=bose(varargin)
% y = bose(p, x, [y]) : Bose
%
%   iFunc/bose Bose fitting function
%     y = 1 ./ (exp(p(1) * x) - 1);
%
% Reference: http://en.wikipedia.org/wiki/Bose%E2%80%93Einstein_statistics
%
% input:  p: Bose model parameters (double)
%            p = [ h/2pi/Kb/T   in 'x' units ]
%          or 'guess'
%         x: axis (double)
%         y: when values are given and p='guess', a guess of the parameters is performed (double)
% output: y: model value
% ex:     y=bose([1], -10:10); or y=plot(bose);
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot

y.Name       = [ 'Bose (1D) [' mfilename ']' ];
y.Description='Bose-Einstein distribution fitting function. Ref: http://en.wikipedia.org/wiki/Bose%E2%80%93Einstein_statistics';
y.Parameters = {'Tau h/kT'};
y.Expression = @(p,x) 1 ./ (exp(p(1) * x) - 1);
y.Dimension  = 1;   
y.Guess      = @(x,signal) log(1./mean(signal(:))+1)/mean(abs(x(:)));

y = iFunc(y);

if length(varargin)
  y = y(varargin{:});
end
