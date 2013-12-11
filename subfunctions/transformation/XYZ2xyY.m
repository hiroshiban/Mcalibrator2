function xyY=XYZ2xyY(XYZ)

% Converts XYZ tristimulus values to CIE1931 xyY.
% function xyY=XYZ2xyY(XYZ)
%
% Compute chromaticity and luminance from
% from tristimulus values.
%
% [input]
% XYZ : XYZ values, [3 x n] matrix
%
% [output]
% xyY : xyY values, [3 x n] matrix
%
%
% Created    : "2012-04-09 20:53:01 ban"
% Last Update: "2013-12-11 22:08:03 ban (ban.hiroshi@gmail.com)"

xyY=zeros(3,size(XYZ,2));
for i=1:1:size(xyY,2)
  xyY(1,i)=XYZ(1,i)./sum(XYZ(:,i));
  xyY(2,i)=XYZ(2,i)./sum(XYZ(:,i));
  xyY(3,i)=XYZ(2,i);
end

return
