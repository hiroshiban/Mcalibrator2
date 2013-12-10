function a = ylabel(a, lab)
% b = ylabel(s,label) : Change iData Y axis label
%
%   @iData/ylabel function to change the Y axis (rank 1, rows) label
%     ylabel(s) returns the current Y axis label
%   The input iData object is updated if no output argument is specified.
%
% input:  s: object or array (iData)
%         label: new Y label (char/cellstr)
% output: b: object or array (iData)
% ex:     b=ylabel(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plot, iData/xlabel, iData/label, iData/zlabel, iData/clabel

if nargin ==1
  if isvector(a) == 1
    a = label(a, 0);
  else
	  a = label(a, 1);
  end
  return
else
	if isvector(a) == 1
    a = label(a, 0, lab);
  else
	a = label(a, 1, lab);
  end
end

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),a);
end

