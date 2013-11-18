function ResetDisplayGammaPTB(brightness_ratio)

% function ResetDisplayGammaPTB(:brightness_ratio)
% (: is optional)
%
% Resets gamma tables to default linear scale(s).
% Psychtoolbox is required.
%
% [input]
% brightness_ratio : ratio from maximum brightness, 0.0-1.0
%                    1.0 by default
%
% !!!NOTICE!!!
% If the brightness_ratio is too small, graphics adaptor
% could not handle it to assign voltage, and will result in error.
% So brightness_ratio>=0.5 is recommended.
%
%
% Created    : "2011-09-06 17:44:10 banh"
% Last Update: "2013-07-05 17:47:02 ban"

% check input variable
if nargin<1, brightness_ratio=1.0; end

% generate default gamma table (no correction)
gamma_tbl=brightness_ratio*(repmat(linspace(0.0,1.0,256),3,1))';

screencount=size(Screen('screens'),2)-1;

% applying the default gamma table
for ii=0:screencount
  Screen('loadnormalizedgammatable',ii,gamma_tbl);
end

return
