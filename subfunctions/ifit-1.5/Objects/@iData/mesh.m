function a = mesh(a, option)
% h = mesh(s,option) : Plot a 2D/3D object as mesh
%
%   @iData/mesh function to plot a 2D or 3D object
%     2D objects are shown as a mesh
%
% input:  s: object or array (iData)
%         option: global option for 2D and 3D plots: 
%                 flat, interp, faceted (for shading)
%                 transparent, light, clabel, colorbar, hide_axes
%                 axis tight, axis auto, view2, view3
%                 painters (bitmap drawing), zbuffer (vectorial drawing)
% output: h: graphics object handles (cell)
% ex:     mesh(iData(peaks)); mesh(iData(flow));
%
% Version: $Revision: 1035 $
% See also iData, iData/plot

if nargin ==1
	option='';
end
h = plot(a, [ 'mesh ' option ]);



