function a = ctranspose(a)
% b = ctranspose(s) : complex conjugate transpose of iFunc object
%
%   @iFunc/ctranspose function to return the complex conjugate transpose of data sets
%   which corresponds to syntax: b = s'
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=ctranspose(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/transpose, iFunc/ctranspose, iFunc/setaxis, iFunc/getaxis

if numel(a) > 1
  a = builtin('ctranspose', a);
elseif ndims(a) <=2
  a = iFunc_private_unary(a, 'ctranspose');
else
  a = permute(a, [2 1]);
end
