function h = contour3(a, option, varargin)
% h = contour3(s,option) : Plot a 2D/3D object as 3D contour
%
%   @iData/contour3 function to plot a 2D or 3D object
%     2D objects are shown as a 3D contour
%
% input:  s: object or array (iData)
%         option: global option for 2D and 3D plots: 
%                 flat, interp, faceted (for shading)
%                 transparent, light, clabel, colorbar, hide_axes
%                 axis tight, axis auto, view2, view3
%                 painters (bitmap drawing), zbuffer (vectorial drawing)
% output: h: graphics object handles (cell)
% ex:     contour3(iData(peaks)); contour3(iData(flow));
%
% Version: $Revision: 1035 $
% See also iData, iData/plot

if nargin <=1
	option='';
end
if ischar(option)
  h = plot(a, [ 'contour3 ' option ], varargin{:});
else
  h = plot(a, 'contour3', option , varargin{:});
end
