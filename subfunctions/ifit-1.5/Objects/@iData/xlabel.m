function a = xlabel(a, lab)
% b = xlabel(s,label) : Change iData X axis label
%
%   @iData/xlabel function to change the X axis (rank 2, columns) label
%     xlabel(s) returns the current X axis label
%   The input iData object is updated if no output argument is specified.
%
% input:  s: object or array (iData)
%         label: new X label (char/cellstr)
% output: b: object or array (iData)
% ex:     b=xlabel(a);
%
% Version: $Revision: 1158 $
% See also iData, iData/plot, iData/label, iData/ylabel, iData/zlabel, iData/clabel

if nargin ==1
  if isvector(a) == 1
	  a = label(a, 1);
  else
    a = label(a, 2);
  end
  return
else
  if isvector(a) == 1
    a = label(a, 1, lab);
  else
	  a = label(a, 2, lab);
  end
end

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),a);
end

