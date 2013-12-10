function b = smooth(a, varargin)
% s = smooth(a) : smooth iData objects
%
%   @iData/smooth function to smooth iData objects
%     The smooth method uses a Robust spline smoothing or Savitzky-Golay algorithm
%     The spline smoothing relies on a frequency spline smoothing (discrete cosine
%     transform), whereas the Savitzky-Golay uses a generalized moving average 
%     with filter coefficients determined by an unweighted linear least-squares 
%     regression and a polynomial model of specified degree (default is 2).
%     The spline method is shape preserving, whereas the Savitzky-Golay may lead
%     to important distribution modifications.
%
%   Z = SMOOTH(Y) automatically smoothes the uniformly-sampled array Y. Y
%   can be any N-D noisy array (time series, images, 3D data,...). Non
%   finite data (NaN or Inf) are treated as missing values.
%
%   Z = SMOOTH(Y,S) smoothes the data Y using the smoothing parameter S.
%   S must be a real positive scalar. The larger S is, the smoother the
%   output will be. If the smoothing parameter S is omitted (see previous
%   option) or empty (i.e. S = []), it is automatically determined using
%   the generalized cross-validation (GCV) method.
%
%   Z = SMOOTH(Y,W) or Z = SMOOTH(Y,W,S) specifies a weighting array W of
%   real positive values, that must have the same size as Y. Note that a
%   nil weight corresponds to a missing value.
%
%   Z = SMOOTH(Y,'sgolay') uses the Savitzky-Golay method (2nd order)
%   Z = SMOOTH(Y,'sgolay',degree) uses the Savitzky-Golay method with polynomial 
%   degree specified by degree.
%   Z = SMOOTH(Y,span,'sgolay',degree) uses the number of data points specified 
%   by span in the Savitzky-Golay calculation. span must be odd and degree must 
%   be less than span.
%   Z = SMOOTH(Y,span,'sgolay',degree,dimensions) specifies the dimensions along
%   which the Savitzky-Golay filter should be applied (integer or vector up to ndims).
%
%   Robust smoothing
%   ----------------
%   Z = SMOOTHN(...,'robust') carries out a robust smoothing that minimizes
%   the influence of outlying data.
%
%   Reference
%   --------- 
%   Garcia D, Robust smoothing of gridded data in one and higher dimensions
%   with missing values. Computational Statistics & Data Analysis, 2010. 
%   <a href="matlab:web('http://www.biomecardio.com/pageshtm/publi/csda10.pdf')">PDF download</a>
%   http://www.biomecardio.com/matlab/smoothn.html
%
%   Numerical recipes in C. p 650
%
% input:  a: object or array (iData/array of)
% output: s: smoothed data set (iData)
% ex:     c=smooth(a);
%
% Version: $Revision: 1169 $
% See also iData, iData/interp

% smoothn is in private

% handle input iData arrays
if numel(a) > 1
  b = zeros(iData, size(a));
  for index=1:numel(a)
    b(index) = feval(mfilename, a(index), varargin{:});
  end
  return
end

% check if we request Savitzky-Golay method
method='spline';  % default
vargs = varargin; % varargin for calling SG
dimensions=0;     % array of ranks to apply SG to
for index=1:min(numel(vargs), 2)
  if strcmpi(vargs{index}, 'sgolay')
    method='sgolay';
    vargs(index) = [];
    if length(vargs) >= 2
      dimensions = vargs{end}; % ranks to consider are specified
      vargs(end) = [];
    end
    break;
  end
end

b = copyobj(a);
if strcmp(method, 'sgolay')
  % use Savitzky-Golay
  
  % iteratively call SG 1D by putting the dimension to apply as 1st
  s = subsref(a,struct('type','.','subs','Signal'));
  
  for index=1:ndims(a)
    if dimensions && all(dimensions ~= index), % skip this rank if not specified
      continue; end
    if index > 1, s  = permute(s, [ index 1 ]); end
    
    s = reshape(smoothsg1d(s(:), vargs{:}), size(s));
    
    if index > 1, s  = permute(s, [ index 1 ]); end
  end
  b = set(b, 'Signal', s);
else
  % use discrete cosine transform filter
  b = set(b, 'Signal', smoothn(subsref(a,struct('type','.','subs','Signal'), varargin{:})));
end


b = iData_private_history(b, mfilename, a, varargin{:});

% ------------------------------------------------------------------------------
function [ny,c] = smoothsg1d(yd,N,M)
% smooth : Data smoothing by Savitzky-Golay method
%Syntax: [smoothed_y, coefs] = smoothsg1d(y,{N,M})
%
% Smoothes the y signal by M-th order Savitzky-Golay method with N points.
% This algorithm assumes that corresponding x axis is evenly spaced.

% Author:  EF <farhi@ill.fr>
% Description:  data smoothing by Savitzky-Golay method

% Part of 'Spectral tools'. E.Farhi. 07/96
% From : Numerical recipes in C. p 650

% Argument processing -----------------------------------------------
% uses : 

if (nargin < 1)
	error('usage: [smoothed_y, coefs] = smooth(y,{N,M=2})');
end

if nargin < 3, M = []; end
if isempty(M), M=2; end

if nargin < 2, N = []; end
if isempty(N), N=5; end

if N < M, N=M+1; end 

%  Savitzky-Golay coefficients -----------------------------------------------
N = ceil(N/2);

A = zeros (2*N +1, M+1);
c = zeros(1,2*N+1);

n=(-N):N;
for j=0:M
    A(:,j+1) = n'.^j;		% Aij = i^j
end

B = pinv(A'*A);
B = B(1,1:(M+1));

for n=1:(2*N+1)
  c(n) = A(n,:) * B';	% these are Savitzky-Golay coefficients
end

% Smoothing ------------------------------------------------------------------
nd = size(yd, 1);
yd = yd(:);
ny = zeros(size(yd));

for n=1:(2*N+1)
  ny((N+1):(nd-N)) = ny((N+1):(nd-N)) + c(n) * yd(n:(nd-2*N-1+n));
end
for n=1:N
  ny(n)=yd(n);
  ny(nd-n+1) = yd(nd-n+1);
end
