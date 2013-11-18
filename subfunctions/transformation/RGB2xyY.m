function xyY = RGB2xyY(RGB,phosphers,flares)

% function xyY=RGB2xyY(RGB,phosphers,:flares)
% (: is optional)
%
% Compute phospher coodinates CIE1931 xyY from RGB(0 - 1).
%
% [input]
% RGB        : RGB video input values, [3 x n] matrix
% phosphers  : a 3 by 3 matrix. Each column is
%              tristimulus coordinates of a phospher:
%              [Rx Gx Bx;Ry Gy By; RY GY BY]
% flares     : zero-level xyY (light leaks), 3 x n matrix
%              flares=repmat([x;y;Y],1,size(myxyY,2));
%
% [output]
% xyY        : CIE9131 xyY values, [3 x n] matrix
%
% [note]
% transformation is done as
% RGB --> XYZ --> xyY
%
%
% Created    : "2012-04-09 20:51:42 ban"
% Last Update: "2012-04-19 06:04:08 ban"

% check input variables
if nargin<2, help(mfilename()); xyY=[]; return; end
if nargin<3, flares=[]; end

if ~isempty(flares) && (size(RGB,1)~=size(flares,1))
  error('sizes of myxyY and flares mismatch. check input variable.');
end

% convert xyY to XYZ
pXYZ=xyY2XYZ(phosphers);

% subtract flares
if ~isempty(flares)
  fXYZ=xyY2XYZ(flares);
  pXYZ=pXYZ-repmat(fXYZ,1,3);
end

XYZ=RGB2XYZ(RGB,pXYZ);

% put back flares
if ~isempty(flares), XYZ=XYZ+repmat(fXYZ,1,size(XYZ,2)); end

% convert XYZ to xyY
xyY=XYZ2xyY(XYZ);

return
