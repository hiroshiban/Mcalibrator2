function b = pca(a, varargin)
% [b] = pca(X, k) : Principal component analysis of iData object(s)
%
%   @iData/pca function to perform a Principal component analysis of object(s)
%
%   b = pca(a,k) computes the principal component analysis of an object in a k-D
%     space representation. This corresponds to a classification of the objects
%     rows, searching for similarities/correlations. The resulting principal 
%     component coefficients object contains the same number of rows as 'a', and
%     k columns for coordinates.
%     Rows (rank 1) of X correspond to observations and further ranks correspond 
%     to variables.
%   b = pca(a) assumes k=2 (2D space classifier).
%   b = pca([a1 a2 ...], k) performs the PCA along all objects specified in the 
%     array, and return the principal component coefficients. The resulting object
%     contains as many rows as the number of objects specified, and k columns.
%   b = pca(a, key, value, ...)
%     specifies the PCA configuration as key=value pairs:
%       'NumComponents',k
%         Number of components requested, specified as the comma-separated pair
%         consisting of 'NumComponents' and a scalar integer k satisfying 
%         0 < k <= p, where p is the number of original variables in X. When 
%         specified, pca returns the first k PCA coefficients.
%       'Centered', True(default) or False
%         Center the variables by subtracting the mean values
%       'VariableWeights', false or 'variance'
%         'variance' to normalize variables to their variance (default)
%
% input:  X: object or array (iData)
%         k: number of components wanted (integer, default is 2)
% output: b: principal component object (iData)
% ex:     b=pca(a); plot(b); text(b{1},b{2}, get(a,'Title'));
%
% See: http://en.wikipedia.org/wiki/Principal_component_analysis
%
% Version: $Revision: 1035 $
% See also iData, iData/kmeans, iData/cwt, iData/corrcoef

% handle input iData arrays
if numel(a) > 1
  % first align all objects (union)
  a = union(a);
  labls = get(a, 'Title');
  % then add all array signals as 1D vectors, one per row
  for index=1:numel(a)
    s = subsref(a(index),struct('type','.','subs','Signal'));
    a(index) = set(a(index), 'Signal', s(:)');
  end
  s = [];
  a = cat(2, a);
  
  % then call pca
  b = pca(a, varargin{:});
  return
end

% default config
k         = 2;
algorithm = 'svd';
centered  = 1;
scale     = 'variance';

% parse input key/values
for index=1:numel(varargin)
  key = varargin{index};
  if ischar(key) && index < numel(varargin)
    value = varargin{index+1};
    index = index + 1;
  else
    value = [];
  end
  if index==1 && isscalar(key)
    k = key;
  else
    switch lower(key)
    case 'numcomponents'
      k = value;
    case 'centered'
      centered  = value;
    case 'variableweights'
      scale     = value;
    end
  end
end

% get data set signal
S = subsref(a,struct('type','.','subs','Signal'));

[n m] = size(S);

if centered, 
  S=S - repmat(mean(S),[n 1]);
end
if strcmp(scale, 'variance')
  S=S./ repmat(std(S),[n 1]);
end

% compute PCA
[V D] = eig(cov(S)); 
D = diag(D);
[D, index] = sort(D,'descend');
% permute coefficients from highest to lowest weight
V = V(:,index);
% restrict to dimensionality 'k'
if k > size(V,2), k=size(V,2); end
if k > 0
  V = V(:, 1:k);
end
coeff  = V;
latent = D;
score  = S*coeff;

% assemble output object
b = copyobj(a);
b.Data.Observations = 1:size(V,1);
b = setalias(b, 'Observations', 'Data.Observations');
b = setalias(b, 'Coefficients', coeff, 'Principal component coefficients');
b = setalias(b, 'Scores', score, 'Principal component scores');
b = setalias(b, 'Variances', latent, 'Principal component variances');
b = set(b, 'Signal', 'Observations', 'Error', 0);
for index=1:k
  b.Data.([ 'PCA' num2str(index)]) = V(:,index);
  b = setalias(b, [ 'PCA' num2str(index)], ['Data.PCA' num2str(index)] );
  b = setaxis( b, index, [ 'PCA' num2str(index)]);
end

b = iData_private_history(b, mfilename, a, varargin{:});

