function ApplyDisplayGammaPTB(gammatable)

% function ApplyDisplayGammaPTB(gammatable)
% (: is optional)
%
% Apply gamma table to the current display(s).
% Psychtoolbox is required.
%
% [input]
% gammatable : display gamma table(s) to be applied,
%              [256x3] or [256x1] matrix, or cell structure
%              if gammatable is given as a cell structure,
%              gammatable{1,2,3,...} will be applied to 1st, 2nd, 3rd,... display(s)
%              gammatable{n}=[256x3(r,g,b)] or [256x1(gray-scale)] matrix.
%
%
% Created    : "2011-09-06 17:44:10 banh"
% Last Update: "2013-07-05 17:47:24 ban"

% check input variable
if nargin<1, help(mfilename()); return; end
if ~iscell(gammatable), gammatable={gammatable}; end

% check gamma table size
for ii=1:1:length(gammatable)
  if size(gammatable{ii},2)~=1 && size(gammatable{ii},2)~=3
    error('gammatable should be 255x3 or 255x1 matrix. check input variable.');
  end
end

% get the number of screens
screencount=size(Screen('screens'),2);

% adjust gamma table length
if length(gammatable)~=1 && length(gammatable)~=screencount
  error('the number of gamma tables and screens mismatched. check input variable.');
elseif length(gammatable)==1 && length(gammatable)<screencount
  for ii=2:1:screencount
    gammatable{ii}=gammatable{1};
  end
end

% applying the default gamma table
for ii=1:1:screencount
  Screen('loadnormalizedgammatable',ii-1,gammatable{ii});
end

return
