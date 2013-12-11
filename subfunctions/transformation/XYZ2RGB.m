function RGB=XYZ2RGB(XYZ,phosphorXYZ)

% Converts XYZ tristimulus values to RGB video inputs.
% function RGB=XYZ2RGB(XYZ,phosphorXYZ)
%
% Compute phosphor coodinates RGB(0 - 1) from XYZ.
%
% [input]
% XYZ         : XYZ values, [3 x n] matrix
% phosphorXYZ : a 3 by 3 matrix. Each column is
%               tristimulus coordinates of a phosphor:
%               [RX GX BX;RY GY BY; RZ GZ BZ]
%
% [output]
% RGB        : RGB values, [3 x n] matrix
%
%
% Created    : "2012-04-09 20:51:42 ban"
% Last Update: "2013-12-11 22:08:13 ban (ban.hiroshi@gmail.com)"

RGB=phosphorXYZ\XYZ;

return
