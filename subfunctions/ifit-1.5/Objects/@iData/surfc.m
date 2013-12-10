function h = surfc(a, option)
% h = surfc(s,option) : Plot a 2D/3D object as surface+contour
%
%   @iData/surfc function to plot a 2D or 3D object with contour
%
% input:  s: object or array (iData)
%         option: global option for 2D and 3D plots: 
%                 flat, interp, faceted (for shading)
%                 transparent, light, clabel
%                 axis tight, axis auto, view2, view3
%                 painters (bitmap drawing), zbuffer (vectorial drawing)
% output: h: graphics object handles (cell)
% ex:     surfc(iData(peaks)); surfc(iData(flow));
%
% Version: $Revision: 1035 $
% See also iData, iData/plot

if nargin ==1
	option='';
end
h = plot(a, [ 'surfc ' option ]);



