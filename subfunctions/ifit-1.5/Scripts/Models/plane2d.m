function signal=plane2d(varargin)
% signal = plane2d(p, x, y, {signal}) : Planar function
%
%   iFunc/plane2d Planar function (fit 2D function/model)
%       signal = p(1)*x+p(2)*y+p(3)
%
% input:  p: plane2d model parameters (double array)
%            p = [  'Slope_X' 'Slope_Y' 'Background' ]
%          or 'guess'
%         x: axis along rows    (double)
%         y: axis along columns (double)
%    signal: when values are given, a guess of the parameters is performed (double)
% output: signal: model value
% ex:     signal=plane2d([1 2 .5 .2 .3 30 .2], -2:.1:2, -3:.1:3); or plot(plane2d);
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot, gauss

signal.Name           = [ 'Planar function (2D) [' mfilename ']' ];
signal.Parameters     = { 'Slope_X' 'Slope_Y' 'Background' };
signal.Description    = '2D Planar function';
signal.Dimension      = 2;         % dimensionality of input space (axes) and result
signal.Guess          = [];        % default parameters
signal.Expression     = @(p,x,y) p(1)*x+p(2)*y+p(3);

signal=iFunc(signal);

if length(varargin)
  signal = signal(varargin{:});
end

