function s = trapz(a,dim)
% s = trapz(a,dim) : computes the integral of iData objects elements along given dimension
%
%   @iData/trapz function to compute the integral of the data set along a given dimension
%     trapz(a,dim) integrates along axis of rank dim. The axis is then removed.
%       default is to use dim=1. If dim=0, integration is done on all axes and 
%       the total is returned as a scalar value. If dim='radial', the integration 
%       is done radially (R=sqrt(sum(axes^2)).
%       trapz is complementary to sum and camproj, but takes into account axes.
%
% input:  a: object or array (iData/array of)
%         dim: dimension to integrate (int/array of, or 'radial')
% output: s: integral of elements (iData/scalar)
% ex:     c=trapz(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/cumsum, iData/camproj, iData/sum

if ~isa(a, 'iData')
  iData_private_error(mfilename,[ 'syntax is ' mfilename '(iData, dim)' ]);
end

if nargin < 2, dim=1; end

if strcmp(dim, 'radial')
  s = camproj(a, dim);
else
  s = iData_private_sumtrapzproj(a,dim, 'trapz');
end

