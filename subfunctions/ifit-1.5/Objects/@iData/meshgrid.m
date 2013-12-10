function b = meshgrid(a, method)
% s = meshgrid(a) : transforms an iData object so that its axes are grids
%
%   @iData/meshgrid function to transform iData object axes so that they are
%     on a regular grid, as obtained from ndgrid. When the initial axes are not
%     perpendicular/regular, the object Signal is interpolated on the new grid.
%   meshgrid(a, 'vector...') forces all axes as vectors
%
% input:  a: object or array (iData)
%         method: 'linear','cubic','spline','nearest'
%                 'vector' to get only vector axes
% output: s: object (iData)
% ex:     c=meshgrid(a); c=meshgrid(a, 'vector linear')
%
% Version: $Revision: 1035 $
% See also iData, iData/interp, iData/hist

if nargin < 2
  method = 'linear';
end

% handle input iData arrays
if numel(a) > 1
  b = zeros(iData, numel(a), 1);
  parfor index=1:numel(a)
    b(index) = meshgrid(a(index),method);
  end
  b = reshape(b, size(a));
  return
end

% check axes dimensions
s_dims = size(a); % Signal/object dimensions

parfor index=1:ndims(a)
  v = getaxis(a, index);

  % compute the initial axis length
  if isvector(v), a_len = numel(v);
  else            a_len = size( v, index);
  end
  if isvector(a) >= 2 && a_len > prod(size(a))^(1/ndims(a))*2 % event data set
    a_len = ceil(prod(size(a))^(1/ndims(a))*2);
  end
  if a_len == 1, a_len = 2; end
  s_dims(index) = a_len;

end
if ndims(a) == 1
  s_dims = [ max(s_dims) 1 ];
end

if isvector(a) > 2
  b = hist(a, s_dims);
  return;
end

% create a regular grid
[f_axes, changed] = iData_meshgrid(a, s_dims, method);
method            = strtrim(strrep(method, 'vector', ''));

b = copyobj(a);
% interpolate if needed
if changed
  b = interp(b, f_axes, method);
else
  % transfer grid axes to object
  for index=1:length(f_axes)
    b = setaxis(b, index, f_axes{index});
  end
end



