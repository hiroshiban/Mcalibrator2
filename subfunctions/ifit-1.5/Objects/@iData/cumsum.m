function b = cumsum(a,dim)
% s = cumsum(a,dim) : computes the cumulative sum of iData objects elements
%
%   @iData/cumsum function to compute the cumulative sum of the elements of the data set
%     cumsum(a,dim) accumulates along axis of rank dim.
%
% input:  a: object or array (iData)
%         dim: dimension to accumulate (int)
% output: s: accumulated sum of elements (iData)
% ex:     c=cumsum(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plus, iData/sum, iData/prod, iData/cumprod

if ~isa(a, 'iData')
  iData_private_error(mfilename,[ 'syntax is ' mfilename '(iData, dim)' ]);
end

if nargin < 2, dim=1; end

b = iData_private_sumtrapzproj(a,dim, 'cumsum');
