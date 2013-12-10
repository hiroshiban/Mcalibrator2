function s = rotate(a, theta)
% s = rotate(a, theta) : computes the rotation of iData objects around the origin
%
%    @iData/rotate function to compute the rotation of iData object around the origin
%     
%      rotate(a) rotates around the Signal axis ('vertical') with 180 angular steps
%      rotate(a, n) rotates using n angular steps in full revolution
%      rotate(a, theta) rotates only on the specified theta values/range
%
%      The resulting object dimensionality is increased by 1.
%
% input:  a:     object or array (iData/array of)
%         theta: single integer to specify how many steps in the revolution, or
%                an angular range (vector in radians)
% output: s: rotated object (iData)
% ex:     c=rotate(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/camproj

  if nargin < 2,      theta = []; end
  if isempty(theta),  theta = 0; end % will use the default
  if isscalar(theta), 
    if theta<=0, theta = 20; end
    theta = linspace(0, 2*pi, theta);
  elseif length(theta) == 2
    theta = linspace(min(theta), max(theta), 20);
  end

  % handle input iData arrays
  if numel(a) > 1
    s = zeros(iData, numel(a), 1);
    parfor index=1:numel(a)
      s(index) = feval(mfilename, a(index), theta);
    end
    s = reshape(s, size(a));
    return
  end
  
  % compute vector axes
  s    = copyobj(a);
  s    = interp(s, 1); % make sure we use a regular grid (use ndgrid on current object)
  Axes = cell(1, ndims(a)+1);
  parfor index=1:length(Axes)
    Axes{index} = unique(getaxis(s, index));
  end
  % add Theta
  Axes{end} = theta;
  
  % create a new extended axis set (prepare new object)
  [Axes{:}] = ndgrid(Axes{:});
  
  % now we rotate the X axis, create a new axis (extend dim), and extend Signal
  % with bsxfun
  for index=2:ndims(a)
    s = setaxis(s, index, Axes{index});
  end
  s = setaxis(s, 1,          Axes{1}.*cos(Axes{end}));
  s = setaxis(s, ndims(s)+1, Axes{1}.*sin(Axes{end})); % add axis
  
  % create a '1' vector for the last (new) dimension
  n = ones(1, ndims(a)+1); n(end) = length(theta);
  v = ones(n); % a long vector perpendicular to the current objects
  S = get(s, 'Signal'); if isvector(S) && size(S,1) == 1, S=S'; end
  s = set(s, 'Signal', bsxfun(@times, S, v));

  e = getalias(a, 'Error');
  if ~isnumeric(e), e=get(a, 'Error'); end
  if  isnumeric(e) && length(e) > 1, 
    if isvector(e) && size(e,1) == 1, e=e'; end
    s = set(s, 'Error', bsxfun(@times, e, v));
  end
  clear e
  
  m = getalias(a, 'Monitor');
  if ~isnumeric(m), m=get(a, 'Monitor'); end
  if isnumeric(m) && length(m) > 1, 
    if isvector(m) && size(m,1) == 1, m=m'; end
    s = set(s, 'Monitor', bsxfun(@times, m, v));
  end
  clear m

  s.Command=a.Command;
  s = iData_private_history(s, mfilename, a, theta);
  
