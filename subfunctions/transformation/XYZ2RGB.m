function RGB=XYZ2RGB(XYZ,PhospherXYZ)

% function RGB=XYZ2RGB(XYZ,PhospherXYZ)
%
% Compute phospher coodinates RGB(0 - 1) from XYZ.
%
% [input]
% XYZ         : XYZ values, [3 x n] matrix
% PhospherXYZ : a 3 by 3 matrix. Each column is
%               tristimulus coordinates of a phospher:
%               [RX GX BX;RY GY BY; RZ GZ BZ]
%
% [output]
% RGB        : RGB values, [3 x n] matrix
%
%
% Created    : "2012-04-09 20:51:42 ban"
% Last Update: "2012-04-09 22:20:44 ban"

RGB=PhospherXYZ\XYZ;

return
