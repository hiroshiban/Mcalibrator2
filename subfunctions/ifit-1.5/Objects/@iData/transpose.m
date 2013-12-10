function a = transpose(a)
% b = transpose(s) : non-conjugate transpose of iData object
%
%   @iData/transpose function to return the non-conjugate transpose of data sets
%     which corresponds to syntax: b = s.'
%   When the argument is an iData array, each element is transposed. To
%     transpose the array itself, use ctranspose(s) or b=s'
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=transpose(a);
%
% Version: $Revision: 1071 $
% See also iData, iData/transpose, iData/ctranspose, iData/setaxis, iData/getaxis

if numel(a) > 1
  a = iData_private_unary(a, 'transpose'); % a = builtin('transpose', a);
elseif ndims(a) <=2
  a = iData_private_unary(a, 'transpose');
else
  a = permute(a, [2 1]);
end

