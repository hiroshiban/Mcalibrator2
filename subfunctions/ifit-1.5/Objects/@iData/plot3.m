function h = plot3(a, option)
% h = plot3(s,option) : Plot a 2D/3D object as separate points or semi-transparent volume
%
%   @iData/plot3 function to plot a 2D or 3D object
%     2D objects are shown as separate points in one single color
%     3D objects are shown as a semi-transparent volume
%     The slice(a) method opens the interactive sliceomatic 3D viewer.
%
% input:  s: object or array (iData)
%         option: global option for 2D and 3D plots: 
%                 flat, interp, faceted (for shading)
%                 transparent, light, clabel
%                 axis tight, axis auto, view2, view3
%                 painters (bitmap drawing), zbuffer (vectorial drawing)
% output: h: graphics object handles (cell)
% ex:     plot3(iData(peaks)); plot3(iData(flow));
%
% Version: $Revision: 1035 $
% See also iData, iData/plot

if nargin ==1
	option='';
end
h = plot(a, [ 'plot3 ' option ]);



