function a=circshift(a, dim, shift)
% b=circshift(a, rank, shift): shifts the axis of specified rank by a value
%
%   @iData/circshift function to shift iData object axes
%     This is euivalent to a{rank} = a{rank}+shift;
%
% input:  a:     object or array (iData)
%         rank:  axis rank (scalar)
%         shift: value to shift the axis with (scalar)
% output: b: object or array (iData)
%
% Version: $Revision: 1060 $
% See also  iData/getaxis, iData/setaxis

if nargin < 3
  return
end

% handle input iData arrays
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index), dim, shift);
  end
  if nargout == 0 & length(inputname(1))
    assignin('caller',inputname(1),a);
  end
  return
end

a = setaxis(getaxis(a, dim)+value);
  
if nargout == 0 & length(inputname(1))
  assignin('caller',inputname(1),a);
end
