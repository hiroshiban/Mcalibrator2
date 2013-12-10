function a = sparse(a)
% b = sparse(s) : Convert iData object storage to sparse
%
%   @iData/sparse function to use sparse storage, which only stores
%   non zeros elements in Signal, Error and Monitor. This may be usefull
%   for event based storage where most events are zeros.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=sparse(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/full, iData/sparse

a = iData_private_unary(a, 'sparse');

