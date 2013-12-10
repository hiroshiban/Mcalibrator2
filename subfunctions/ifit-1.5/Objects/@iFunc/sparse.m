function a = sparse(a)
% b = sparse(s) : Convert iFunc object storage to sparse
%
%   @iFunc/sparse function to use sparse storage, which only stores
%   non zeros elements in Signal, Error and Monitor. This may be usefull
%   for event based storage where most events are zeros.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=sparse(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/full, iFunc/sparse

a = iFunc_private_unary(a, 'sparse');

