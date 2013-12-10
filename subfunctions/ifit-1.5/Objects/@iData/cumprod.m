function b = cumprod(a,dim)
% s = cumprod(a,dim) : computes the cumulative product of iData objects elements
%
%   @iData/cumprod function to compute the cumulative product of the elements of the data set
%     cumprod(a,dim) operates along axis of rank dim.
%
% input:  a: object or array (iData)
%         dim: dimension to accumulate (int)
% output: s: accumulated product of elements (iData)
% ex:     c=cumprod(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plus, iData/sum, iData/prod, iData/cumprod
if ~isa(a, 'iData')
  iData_private_error(mfilename,[ 'syntax is ' mfilename '(iData, dim)' ]);
end

if nargin < 2, dim=1; end

b = iData_private_sumtrapzproj(a,dim, 'cumprod');
