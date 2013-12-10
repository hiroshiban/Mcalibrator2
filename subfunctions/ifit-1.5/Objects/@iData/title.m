function a = title(a, lab)
% b = title(s,label) : Change iData Signal label
%
%   @iData/title function to change the Signal label
%     title(s) returns the current Signal label. 
%   To change the object title, use s.Title='new title'
%
% input:  s: object or array (iData)
%         label: new Signal label (char/cellstr)
% output: b: object or array (iData)
% ex:     b=title(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plot

if nargin ==1
	a = label(a, 0);
	return
else
	a = label(a, 0, lab);
end

if nargout == 0 & length(inputname(1))
  assignin('caller',inputname(1),a);
end

