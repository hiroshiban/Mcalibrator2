function b = mean(a, dim)
% b = mean(s, dim) : mean value of iData object
%
%   @iData/mean function to compute the mean value of objects
%     mean(a,dim) averages along axis of rank dim. The axis is then removed.
%       If dim=0, mean is done on all axes and the total is returned as a scalar value. 
%       mean(a,1) accumulates on first dimension (columns)
%     mean(a,-dim) averages on all axes except the dimension specified, i.e.
%       the result is the mean projection of a along dimension dim.
%       All other axes are removed.
%
% input:  a: object or array (iData/array of)
%         dim: dimension to average (int)
% output: s: mean of elements (iData/scalar)
% ex:     c=mean(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/std, iData/combine, iData/mean

if nargin < 2, dim=1; end
if numel(a) > 1
  b = combine(a);
  return
end

s=iData_private_cleannaninf(get(a,'Signal'));
[link, label]          = getalias(a, 'Signal');
cmd=a.Command;
b=copyobj(a);
rmaxis(b); % delete all axes
if dim==1 & ndims(a)==1
  b = mean(s, dim);
  return
elseif dim > 0
  s = mean(s, dim);
  % copy all axes except the one on which operation runs
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
    s = mean(s, index);
  end
  b = s;
  return  % scalar
else  % dim < 0
  % accumulates on all axes except the rank specified
  b = camproj(a, -dim);
end
b.Command=cmd;
b = iData_private_history(b, mfilename, b, dim);
s = b;

