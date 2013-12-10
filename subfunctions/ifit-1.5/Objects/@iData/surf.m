function h = surf(a, option)
% h = surf(s,option) : Plot a 2D/3D object as surface
%
%   @iData/surf function to plot a 2D or 3D object
%     2D objects are shown as a surface
%     3D objects are shown as an isosurface with median value
%     The slice(a) method opens the interactive sliceomatic 3D viewer.
%
% input:  s: object or array (iData)
%         option: global option for 2D and 3D plots: 
%                 flat, interp, faceted (for shading)
%                 transparent, light, clabel
%                 axis tight, axis auto, view2, view3
%                 painters (bitmap drawing), zbuffer (vectorial drawing)
% output: h: graphics object handles (cell)
% ex:     surf(iData(peaks)); surf(iData(flow));
%
% Version: $Revision: 1035 $
% See also iData, iData/plot, iData/colormap, iData/caxis

if nargin ==1
	option='';
end
h = plot(a, [ 'surf ' option ]);


