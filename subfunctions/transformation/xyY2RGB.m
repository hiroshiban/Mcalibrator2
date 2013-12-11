function rgb=xyY2RGB(myxyY,phosphors,flares)

% Converts CIE1931 xyY to RGB video inputs.
% function rgb=xyY2RGB(myxyY,phosphors,:flares)
% (: is optional)
%
% Convert CIE1931 xyY to RGB video input values
%
% [input]
% myxyY     : xyY values you want to display, [3 x n] matrix
% phosphors : RGB phosphor xyY, phosphors = [rx,gx,bx; ry,gy,by; rY,gY,bY];
% flares    : zero-level xyY (light leaks), 3x1 matrix, flares=[x;y;Y];
%
% [output]
% rgb       : rgb values calculated after Flare Correction
%
%
% Created    : "2012-04-16 08:05:27 ban"
% Last Update: "2013-12-11 22:08:31 ban (ban.hiroshi@gmail.com)"

% check input variables
if nargin<2, help(mfilename()); rgb=[]; return; end
if nargin<3, flares=[]; end

if ~isempty(flares) && (size(myxyY,1)~=size(flares,1))
  error('sizes of myxyY and flares mismatch. check input variable.');
end

% convert from xyY to XYZ
XYZ=xyY2XYZ(myxyY);
pXYZ=xyY2XYZ(phosphors);

% subtract flares
if ~isempty(flares)
  fXYZ=xyY2XYZ(flares);
  XYZ=XYZ-repmat(fXYZ,1,size(XYZ,2));
  pXYZ=pXYZ-repmat(fXYZ,1,size(pXYZ,2));
end

% convert XYZ to RGB
rgb=XYZ2RGB(XYZ,pXYZ);

return
