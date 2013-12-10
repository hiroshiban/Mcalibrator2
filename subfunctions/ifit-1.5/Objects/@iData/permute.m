function a = permute(a, order)
% c = permute(a, order) : Permute object dimensions from iData objects/arrays
%
%   @iData/permute rearranges the dimensions of object A so that they
%     are in the order specified by the vector ORDER.  The object produced
%     has the same values as A but the order of the subscripts needed to 
%     access any particular element are rearranged as specified by ORDER.
%   For an N-D array A, numel(ORDER)>=ndims(A). All the elements of 
%     ORDER must be unique.
%   PERMUTE is a generalization of transpose (.') 
%
% input:  a: object or array (iData)
%         order: index of dimensions to swap/permute. 
%                Default is [2 1], that is transpose.
% output: c: object or array (iData)
% ex:     c=permute(iData(rand(2,3,4)),[2 3 1]);
%
% Version: $Revision: 1133 $
% See also iData, iData/size, iData/reshape, iData/resize

% handle iData array: use built-in permute
if nargin ==1, order=[]; end
if isempty(order), order=[2 1]; end % default is transpose

if numel(a) > 1
  a = builtin(mfilename, a, order);
  return
end

% check if order has the right dimension, else pad with other dimensions
if length(order) < ndims(a)
  for index=1:ndims(a)
    if isempty(find(order==index)), order=[ order index]; end
  end
end

% use permute on Signal, Error, Monitor
if ~isvector(a)
  a = iData_private_unary(a, 'permute', order);
end

% then swap axes
if length(a.Alias.Axis) == length(order)    % all axes defined
  a.Alias.Axis = a.Alias.Axis(order);
elseif length(a.Alias.Axis) % some axes are not defined
  ax = a.Alias.Axis;
  for index=(length(ax)+1):length(order)
    ax{index}='';
  end
  a.Alias.Axis = ax(order);
end

