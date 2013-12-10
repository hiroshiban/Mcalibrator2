function a = copyobj(a)
% b = copyobj(s) : makes a copy of iData object
%
%   @iData/copyobj function to return a duplicate of data sets.
%   creates a new iData object with same content as 'a', but different Tag/ID and Date.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=copyobj(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/uplus, iData/findobj

% handle input iData arrays
if numel(a) > 1
  b = zeros(iData,numel(a),1);
  parfor index=1:numel(a)
    b(index) = copyobj(a(index));
  end
  a = reshape(b, size(a));
  return
end

a = iData_private_history(iData_private_newtag(a), mfilename, a);

