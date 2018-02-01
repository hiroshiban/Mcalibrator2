function v=ndims(s)
% d = ndims(s) : get the dimensionality of iData object
%
%   @iData/ndims function to get the number of dimensions of the iData signal.
%
% input:  s: object or array (iData)
% output: dimensionality of Signal in the object (double array)
% ex :    ndims(iData)
%
% Version: $Revision: 1035 $
% See also  iData/size

% EF 11/07/00 creation
% EF 23/09/07 iData implementation

if numel(s) > 1
  v = zeros(size(s)); 
  parfor index=1:numel(s)
    v(index) =ndims(s(index));
  end
  return
end

n = size(s);
if     all(n == 0), v=0;
elseif all(n == 1), v=1;
else
  index=find(n > 1);
  v = length(index);
  if v == 1 & length(getaxis(s)) > 1
    n=n(index);
    % this is for [x,y,z,... vector data (plot3 style)]
    % must count that axes have the length of the signal
    v=0;
    for i_axis=1:length(getaxis(s))
      if length(get(s, s.Alias.Axis{i_axis})) == n
        v = v+1;
      end
    end
    if v == 0 && n
      v=1;
    end
  end
end


