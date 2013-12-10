function a = zlabel(a, lab)
% b = zlabel(s,label) : Change iData Z axis label
%
%   @iData/zlabel function to change the Z axis (rank 3) label
%     zlabel(s) returns the current Z axis label
%   The input iData object is updated if no output argument is specified.
%
% input:  s: object or array (iData)
%         label: new Z label (char/cellstr)
% output: b: object or array (iData)
% ex:     b=zlabel(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plot, iData/xlabel, iData/ylabel, iData/label, iData/clabel

if nargin ==1
	a = label(a, 3);
	return
else
	a = label(a, 3, lab);
end

if nargout == 0 & length(inputname(1))
  assignin('caller',inputname(1),a);
end


