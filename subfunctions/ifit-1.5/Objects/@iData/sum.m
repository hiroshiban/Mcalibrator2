function s = sum(a,dim)
% s = sum(a,dim) : computes the sum of iData objects elements
%
%   @iData/sum function to compute the sum of the elements of the data set
%     sum(a,dim) accumulates along axis of rank dim. The axis is then removed.
%       If dim=0, sum is done on all axes and the total is returned as a scalar value. 
%       If dim='radial', the sum is done radially (R=sqrt(sum(axes^2)).
%       sum(a,1) accumulates on first dimension (columns). 
%       camproj accumulates on all other axes.
%
% input:  a: object or array (iData/array of)
%         dim: dimension to accumulate (int/array of, or 'radial')
% output: s: sum of elements (iData/scalar)
% ex:     c=sum(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/plus, iData/prod, iData/cumsum, iData/mean,
% iData/camproj, iData/trapz, iData/cart2sph

if ~isa(a, 'iData')
  iData_private_error(mfilename,[ 'syntax is ' mfilename '(iData, dim)' ]);
end

if nargin < 2, dim=1; end
if strcmp(dim, 'radial')
  s = camproj(a, dim);
else
  s = iData_private_sumtrapzproj(a,dim, 'sum');
end
