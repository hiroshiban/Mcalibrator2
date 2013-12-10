function data = ind2sub(data, index)
% ind2sub(s,index) : get indexed element in an iData array
%
%   @iData/ind2sub is equivalent to accessing directly the indexed element in arrays,
%         except when the array is of lenght 1.
%         When length(s) is 1, s(1) would return s itself,
%         whereas ind2sub(s,1) returns the first element of its 'Signal',
%
% input:  s:     object or array (iData)
%         index: index in array
% output: s(index)
% ex :    ind2sub(s, 1)
%
% Version: $Revision: 1057 $
% See also iData, iData/disp, iData/get, iData/size

% EF 23/09/07 iData implementation
% ind2sub 
  if nargin < 2, index=[]; end
  if ~length(index), data=[]; return; end

  index = index(index > 0);
  if length(data) > 1, 
    data=data(index);
  else
    if length(data) == 0, data=[]; 
    else 
    	S = get(data,'Signal');
    	data = S(index);
    end
  end    
