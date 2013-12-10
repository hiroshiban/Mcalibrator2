function b = median(a, dim)
% b = median(s, dim) : median value of iData object
%
%   @iData/median function to compute the median value of objects
%     median(a,dim) computes median along axis of rank dim. The axis is then removed.
%       If dim=0, median is done on all axes and the total is returned as a scalar value. 
%       median(a,1) operates on first dimension (columns)
%     median(a,-dim) computes median on all axes except the dimension specified, i.e.
%       the result is the median projection of a along dimension dim.
%       All other axes are removed.
%
% input:  a: object or array (iData/array of)
%         dim: dimension to operate on (int)
% output: s: median of elements (iData/scalar)
% ex:     c=median(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/std, iData/combine, iData/median

if nargin < 2, dim=1; end
if numel(a) > 1
  a = combine(a);
  return
end

s=iData_private_cleannaninf(get(a,'Signal'));
[link, label]          = getalias(a, 'Signal');
cmd=a.Command;
b=copyobj(a);
rmaxis(b); % delete all axes
if dim==1 & ndims(a)==1
  b = median(s, dim);
  return
elseif dim > 0
  s = median(s, dim);
  ax_index=1;
  for index=1:ndims(a)
    if index ~= dim
      setaxis(b, ax_index, getaxis(a, num2str(index)));
      ax_index = ax_index+1;
    end
  end
  setalias(b,'Signal', s, [mfilename ' of ' label ]);     % Store Signal
elseif dim == 0
  for index=1:ndims(a)
    s = median(s, index);
  end
  b = s;
  return  % scalar
else  % dim < 0
  % accumulates on all axes except the rank specified
  for index=1:ndims(a)
    if index~=-dim, s = median(s,index); end
  end
  setaxis(b, 1, getaxis(a, num2str(-dim)));
  setalias(b,'Signal', s, [ 'median projection of ' label ]);     % Store Signal
end
b.Command=cmd;
b = iData_private_history(b, mfilename, b, dim);
s = b;

