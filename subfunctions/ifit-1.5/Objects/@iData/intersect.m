function [ai,bi] = intersect(a, b)
% [ai,bi] = intersect(a, b) : computes object intersection area and values
%
%   @iData/intersect function to intersect axes data sets
%   This function computes the common intersection between data sets
%   Resulting objects are returned, e.g. for performing further operations
%     ai = intersect(a) where 'a' is an object array computes intersection of all elements
%
% input:  a: object or array (iData)
%         b: object (iData)
% output: ai: object or array (iData)
%         bi: object or array (iData)
% ex:     b=intersect(a, a);
%
% Version: $Revision: 1035 $
% See also iData, iData/setaxis, iData/getaxis, iData/interp, iData/union

if nargin == 2
  bi = intersect([a b]);
  ai = bi(1);
  bi = bi(2);
  return
end

if numel(a) == 1, ai=a; bi=a; return; end

% first check if all objects have same axes
all_identical_axes=1;
for index=1:ndims(a(1)) % loop on axes
  x = getaxis(a(1), index);
  for obj=2:numel(a)
    if ~isequal(getaxis(a(obj), index), x)
      all_identical_axes=0; break;
    end
  end
  if ~all_identical_axes, break; end
end
% return if using identical axes: no need to interpolate. retain axes and data.
if all_identical_axes, ai=a; bi=[]; return; end

% compute common axes
c_axis = iData_private_caxis(a,'intersection');

% loop on all iData to interpolate
ai = zeros(iData, numel(a),1); bi=[];

parfor index=1:numel(a)
  ai(index) = interp(a(index), c_axis(1:ndims(a(index))));
end

