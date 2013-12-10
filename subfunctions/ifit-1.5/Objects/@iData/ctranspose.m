function a = ctranspose(a)
% b = ctranspose(s) : complex conjugate transpose of iData object
%
%   @iData/ctranspose function to return the complex conjugate transpose of data sets
%     which corresponds to syntax: b = s'
%   When the argument is an iData array, the whole array is transposed. To
%     transpose each array element, use transpose(s) or b=s.'
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=ctranspose(a);
%
% Version: $Revision: 1071 $
% See also iData, iData/transpose, iData/ctranspose, iData/setaxis, iData/getaxis

if numel(a) > 1
  a = builtin('ctranspose', a);
elseif ndims(a) <=2
  a = iData_private_unary(a, 'ctranspose');
else
  a = permute(a, [2 1]);
end
