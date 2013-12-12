function XYZ = RGB2XYZ(RGB, phosphorXYZ)

% Converts RGB video inputs to XYZ tristimulus values.
% fucntion XYZ = RGB2XYZ(RGB, phosphorXYZ)
%
% Compute XYZ from phosphor coodinates RGB(from 0 to 1).
%
% [input]
% RGB         : RGB video input values, [3 x n] matrix
% phosphorXYZ : a 3 by 3 matrix. Each column is
%               tristimulus coordinates of a phosphor:
%               [RX GX BX;RY GY BY; RZ GZ BZ]
%
% [output]
% XZY         : tristimulus coordinate of input RGB,
%               [3 x n] matrix
%
%
% Created    : "2012-04-19 05:54:54 ban"
% Last Update: "2013-12-11 22:08:47 ban"

XYZ=phosphorXYZ*RGB;

return
