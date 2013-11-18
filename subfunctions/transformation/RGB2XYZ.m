function XYZ = RGB2XYZ(RGB, PhospherXYZ)

% fucntion XYZ = RGB2XYZ(RGB, PhospherXYZ)
%
% Compute XYZ from phospher coodinates RGB(from 0 to 1).
%
% [input]
% RGB         : RGB video input values, [3 x n] matrix
% phospherXYZ : a 3 by 3 matrix. Each column is
%               tristimulus coordinates of a phospher:
%               [RX GX BX;RY GY BY; RZ GZ BZ]
%
% [output]
% XZY         : tristimulus coordinate of input RGB,
%               [3 x n] matrix
%
%
% Created    : "2012-04-19 05:54:54 ban"
% Last Update: "2012-04-19 05:56:01 ban"

XYZ=PhospherXYZ*RGB;

return
