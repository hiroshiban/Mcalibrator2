function b = cumtrapz(a,dim)
% s = cumtrapz(a,dim) : computes the cumulative product of iData objects elements
%
%   @iData/cumtrapz function to compute the cumulative integral (primitive) of the data set
%     cumtrapz(a,dim) operates along axis of rank dim. The axis is then removed.
%       default is to use dim=1. If dim=0, integration is done on all axes and 
%       the total is returned as a scalar value. 
%       cumtrapz is complementary to cumsum and camproj, but takes into account axes.
%
% input:  a: object or array (iData)
%         dim: dimension to integrate (int)
% output: s: accumulated integral of elements, i.e. primitive (iData)
% ex:     c=cumtrapz(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plus, iData/sum, iData/prod, iData/cumsum

if ~isa(a, 'iData')
  iData_private_error(mfilename,[ 'syntax is ' mfilename '(iData, dim)' ]);
end

if nargin < 2, dim=1; end

b = iData_private_sumtrapzproj(a,dim, 'cumtrapz');
