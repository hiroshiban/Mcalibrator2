function data=getDataFromStr(str)

% Gets CIE1931 xyY data from the input string sent from Mcalibrator2.
% function data=getDataFromStr(str)
%
% a subfunction to handle data
% get CIE1931 xyY or RGB values from input string
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2013-12-11 17:23:05 ban"

[my1,my2,my3]=strread(str,'%f,%f,%f','delimiter',';');
data=[my1,my2,my3];

return
