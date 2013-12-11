function [Y,x,y,displayhandler,colorimeterhandler]=MeasureCIE1931xyY(displayhandler,colorimeterhandler,rgb,fullscr_flg,fig_id)

% Measures CIE1931 xyY values for a set of input rgb values using displayhander and colorimeterhandler.
% function [Y,x,y,displayhandler,colorimeterhandler]=...
%            MeasureCIE1931xyY(displayhandler,colorimeterhandler,rgb,:fullscr_flg,:fig_id)
% (: is optional)
%
% This function measures CIE1931 xyY values for a set of input rgb values using displayhandler and colorimeterhandler
%
% [input]
% displayhandler     : function handle to display color window
%                      e.g. displayhander=@DisplayColorWindow;
%                           displayhander=@DisplayColorWindowPTB;
% colorimeterhandler : object handle to manipulate the colorimeter and measure CIE1931 xyY
%                      e.g. colorimeterhandler=pr650;
% rgb                : RGB values to be measured, rgb=[r,g,b];
% fullscr_flg        : if 1, the color window is displayed with full-screen mode, 0 by default
% fig_id             : MATLAB figure or PTB screen handle in which RGB color is displayed
%
% [output]
% Y : CIE1931 Y (luminance)
% x : CIE1931 x
% y : CIE1931 y
% displayhandler     : function handle to display color window
% colorimeterhandler : object handle to manipulate the colorimeter and measure CIE1931 xyY
%
%
% Created    : "2012-04-14 23:24:35 ban"
% Last Update: "2013-12-11 17:48:54 ban (ban.hiroshi@gmail.com)"

% set global variables

% check input variables
if nargin<3, help(mfilename()); Y=[]; x=[]; y=[]; return; end
if nargin<4 || isempty(fullscr_flg), fullscr_flg=0; end
if nargin<5 || isempty(fig_id), fig_id=[]; end

% measure CIE1931 xyY
displayhandler(rgb,fullscr_flg,fig_id);
qq=1; count=1;
while qq~=0 && count<=5
  [qq,Y,x,y,colorimeterhandler]=colorimeterhandler.measure();
  count=count+1;
  if qq~=0
    disp('Measured data qualitity was not satisfied...Re-measuring');
    colorimeterhandler.initialize(1000*count);
  end
end
colorimeterhandler.initialize();

return
