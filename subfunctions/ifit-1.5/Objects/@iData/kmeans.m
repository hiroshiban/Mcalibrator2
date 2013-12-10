function [s,c] = kmeans(a, k)
% [b,c] = kmeans(X, k) : k-means clustering of iData object
%
%   @iData/kmeans function to partition the object X into k classes.
%
%   b = kmeans(a,k) partitions the points in the iData object X into k clusters.
%     The resulting object Signal contains numbers from 1 to 'k' which are indices
%     of segments/partitions.
%     When no cluster can be found, the result is empty.
%   b = kmeans(a) assumes k=2 partitions
%   [b,c] = kmeans(a,k) also returns the centroid of the clusters/partitions/segments.
%
% input:  X: object or array (iData)
%         k: number of partitions wanted (integer, default is 2)
% output: b: object or array with partition indices (iData)
%         c: centroid locations of clusters
% ex:     b=kmeans(a);
%
% See: http://en.wikipedia.org/wiki/K-means_clustering
%
% Version: $Revision: 1035 $
% See also iData, iData/uminus, iData/abs, iData/real, iData/imag, iData/uplus

if nargin < 2
  k = 2;
end

% handle input iData arrays
if numel(a) > 1
  s = zeros(iData, size(a));
  c = cell(size(a));
  parfor index=1:numel(a)
    [ s(index), c{index} ] = feval(mfilename, a(index), k);
  end
  return
end

s = []; c = [];

% now call FastCMeans
S = subsref(a,struct('type','.','subs','Signal'));

X = uint8(S/max(S(:))*2^8); % this is faster and requires much less memory that uint16
X = FastCMeans(X, k);

if all(X == 0)  % no cluster found
  return
end

% create the final object
s=copyobj(a); 
s=iData_private_history(s, mfilename, a, k);

s=set(s, 'Signal', X, 'Error', 0);
s=label(s, 0, 'Clusters/partitions');

% compute centroids
if nargout > 1 && any(X(:) > 0)
  % removes warnings during interp
  iData_private_warning('enter', mfilename);
  for index=1:k
    % use std method with background subtraction
    [this_w, this_c] = std(a.*(X == index), -(1:ndims(a)));
    c = [ c ; this_c ];
  end
  iData_private_warning('exit', mfilename);
end
