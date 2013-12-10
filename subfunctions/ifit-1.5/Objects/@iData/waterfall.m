function h = waterfall(a, option)
% h = waterfall(s,option) : Plot a 2D/3D object as waterfall (side by side lines)
%
%   @iData/waterfall function to plot a 2D or 3D object as a waterfall
%
% input:  s: object or array (iData)
%         option: global option for 2D and 3D plots: 
%                 flat, interp, faceted (for shading)
%                 transparent, light, clabel
%                 axis tight, axis auto, view2, view3
%                 painters (bitmap drawing), zbuffer (vectorial drawing)
% output: h: graphics object handles (cell)
% ex:     waterfall(iData(peaks)); waterfall(iData(flow));
%
% Version: $Revision: 1035 $
% See also iData, iData/plot

if nargin ==1
	option='';
end
h = plot(a, [ 'waterfall ' option ]);



