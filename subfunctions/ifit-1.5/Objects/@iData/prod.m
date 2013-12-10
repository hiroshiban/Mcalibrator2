function s = prod(a,dim)
% s = prod(a,dim) : computes the product of iData objects elements
%
%   @iData/prod function to compute the product of the elements of the data set
%     prod(a,dim) operates along axis of rank dim. The axis is then removed.
%       If dim=0, product is done on all axes and the total is returned as a scalar value. 
%       prod(a,1) operates on first dimension (columns)
%
% input:  a: object or array (iData/array of)
%         dim: dimension to operate (int//array of)
% output: s: product of elements (iData/scalar)
% ex:     c=prod(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plus, iData/prod, iData/cumprod, iData/mean

if ~isa(a, 'iData')
  iData_private_error(mfilename,[ 'syntax is ' mfilename '(iData, dim)' ]);
end

if nargin < 2, dim=1; end

s = iData_private_sumtrapzproj(a,dim, 'prod');

