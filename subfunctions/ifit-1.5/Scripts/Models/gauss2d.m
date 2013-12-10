function signal=gauss2d(varargin)
% signal = gauss2d(p, x, y, {signal}) : 2D Gaussian function
%
%   iFunc/gauss2d 2D Gaussian function (fit 2D function/model)
%     x0=p(2); y0=p(3); sx=p(4); sy=p(5); theta=p(6) [given in deg]
%     a = cos(theta)^2/2/sx/sx + sin(theta)^2/2/sy/sy;
%     b =-sin(2*theta)/4/sx/sx + sin(2*theta)/4/sy/sy;
%     c = sin(theta)^2/2/sx/sx + cos(theta)^2/2/sy/sy;
%     signal = p(1)*exp(-(a*(x-x0).^2+2*b*(x-x0).*(y-y0)+c*(y-y0).^2)) + p(7);
%
% Reference: http://en.wikipedia.org/wiki/Gaussian_function
%
% input:  p: gauss2d model parameters (double)
%            p = [  'Amplitude' 'Centre_X' 'Center_Y'
%                   'HalfWidth_X' 'HalfWidth_Y' 'Angle' 'Background' ] 
%            the rotation angle is given in degrees.
%          or 'guess'
%         x: axis along rows    (double)
%         y: axis along columns (double)
%    signal: when values are given, a guess of the parameters is performed (double)
% output: signal: model value
% ex:     signal=gauss2d([1 2 .5 .2 .3 30 .2], -2:.1:2, -3:.1:3); or plot(gauss2d)
%
% Version: $Revision: 1035 $
% See also iData, iFunc/fits, iFunc/plot, gauss

signal.Name           = [ 'Gaussian-2D function with tilt angle (2D) [' mfilename ']' ];
signal.Description    = '2D Gaussian function with tilt angle. http://en.wikipedia.org/wiki/Gaussian_function';
signal.Parameters     = {  'Amplitude' 'Centre_X' 'Center_Y' 'HalfWidth_X' 'HalfWidth_Y' 'Angle tilt [deg]' 'Background' };
signal.Dimension      = 2;         % dimensionality of input space (axes) and result
signal.Guess          = @(x,y,signal)[ max(signal(:))-min(signal(:)) mean(x(:)) mean(y(:)) std(x(:)) std(y(:)) 20*randn min(signal(:)) ];        % default parameters
signal.Expression     = {'x0=p(2); y0=p(3); sx=p(4); sy=p(5);', ...
  'theta = p(6)*pi/180;', ...
  'aa = cos(theta)^2/2/sx/sx + sin(theta)^2/2/sy/sy;', ...
  'bb =-sin(2*theta)/4/sx/sx + sin(2*theta)/4/sy/sy;', ...
  'cc = sin(theta)^2/2/sx/sx + cos(theta)^2/2/sy/sy;', ...
  'signal = p(1)*exp(-(aa*(x-x0).^2+2*bb*(x-x0).*(y-y0)+cc*(y-y0).^2)) + p(7);' };

signal=iFunc(signal);

if length(varargin)
  signal = signal(varargin{:});
end

