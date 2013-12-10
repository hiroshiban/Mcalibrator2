function a = clabel(a, lab)
% b = clabel(s,label) : Change iData C axis label
%
%   @iData/clabel function to change the C axis (rank 4) label
%     clabel(s) returns the current C axis label
%   The input iData object is updated if no output argument is specified.
%
% input:  s: object or array (iData)
%         label: new C label (char/cellstr)
% output: b: object or array (iData)
% ex:     b=clabel(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plot, iData/xlabel, iData/ylabel, iData/zlabel, iData/label

if nargin ==1
	a = label(a, 4);
	return
else
	a = label(a, 4, lab);
end

if nargout == 0 & length(inputname(1))
  assignin('caller',inputname(1),a);
end

