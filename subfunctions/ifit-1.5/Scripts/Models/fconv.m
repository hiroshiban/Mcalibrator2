function y=fconv(x, h, shape)
%FCONV Fast Convolution/Correlation
%   y = FCONV(x, h, shape) convolves x and h. A deconvolution mode is also possible.
%   The correlation, instead of the convolution, can also be computed.
%   This FFT based convolution should provide the same results as conv2 and convn.
%   It works with x and h being of any dimensionality. When only one argument is given,
%     the auto-convolution/correlation is computed.
%   The accuracy of the conv and xcorr operators depends on the sampling. Peaks should
%     be describes with at least 5 points underneath.
%
%      x = input vector (signal)
%      h = input vector (filter)
%  shape = optional shape of the return value
%          full         Returns the full two-dimensional convolution.
%          same         Returns the central part of the convolution of the same size as x.
%          valid        Returns only those parts of the convolution that are computed
%                       without the zero-padded edges. Using this option, y has size
%                       [mx-mh+1,nx-nh+1] when all(size(x) >= size(h)).
%          deconv       Performs an FFT deconvolution.
%          correlation  Compute the correlation instead of the convolution (one
%                       of the FFT's is then conjugated).
%          pad          Pads the x signal by replicating its starting/ending values
%                       in order to minimize the convolution side effects.
%          center       Centers the h filter so that convolution does not shift
%                       the x signal.
%          normalize    Normalizes the h filter so that the convolution does not
%                       change the x signal integral.
%          background   Remove the background from the filter h (subtracts the minimal value)
%
% ex:     c=fconv(a,b); c=fconv(a,b, 'same pad background center normalize');
%
%      See also FCONVN, FXCORR, CONV, CONV2, FILTER, FILTER2, FFT, IFFT
%
% Version: $Revision: 1112 $


y=[];
if nargin == 0, return; end
if nargin == 1, h = x; end
if isempty(x) || isempty(h), return; end
if nargin < 3, shape = 'full'; end

if isvector(x) && size(x,1) == 1, x=x'; transpose_x=1; else transpose_x=0; end
if isvector(h) && size(h,1) == 1, h=h'; end

% pad the signal
if ~isempty(strfind(shape,'pad')) || ~isempty(strfind(shape,'extend'))
  l = ceil(size(x)/2);
  A = x;
  x = padreplicate(x, l);
end

% suppress background
if (strfind(shape,'background'))
  h = h-min(h(:));
end

% center the filter
if ~isempty(strfind(shape,'center')) ||  ~isempty(strfind(shape,'centre'))
  % determine first moment for each dimension
  Y = {};
  for index=1:length(size(h))
    if size(h, index) == 1
      Y{index} = 1;
    else
      s        = h;
      for i=1:length(size(h))
        if i ~= index
          s = sum(s, i);
        end
      end
      a        = 1:size(h, index);
      f        = sum(s(:).*a(:))./sum(s(:)); % mean index value (center of the filter)
      Y{index} = (f-ceil(size(h, index)/2)):(f+ceil(size(h, index)/2));
    end
  end
  % create a new filter grid which has odd number of elements, centered and interpolate
  if isvector(h)
    Y = Y{1};
    h = interp1(h(:), Y(:), '*linear',0);
  else
    tmp=Y{2}; Y{2} = Y{1}; Y{1} = tmp;
    [Y{:}] = ndgrid(Y{:});
    h = interpn(h, Y{:}, '*linear',0);
  end
end

% normalize the filter
if (strfind(shape,'norm'))
  h = h/sum(h(:));
end

if (strfind(shape,'corr'))
  % rotate the filter by 180 deg for correlation
  Ly=size(h);
  S.type='()';
  for i=1:length(Ly)
    S.subs{i} = Ly(i):-1:1;
  end
  h=subsref(h,S);
end

Ly=size(x)+size(h)-1;
Ly2=Ly;
for i=1:length(Ly)         % Find smallest power of 2 that is > Ly
  Ly2(i)=pow2(nextpow2(Ly(i)));
end

X=fftn(x, Ly2);		       % Fast Fourier transform (pads with zeros up to the next power of 2)
H=fftn(h, Ly2);	           % Fast Fourier transform

if (strfind(shape,'deconv'))
  Y=X./H;      	           % FFT Division= deconvolution
else
  Y=X.*H;      	           % FFT Product = convolution
end
y=ifftn(Y, Ly2);           % Inverse fast Fourier transform

% Final cleanups:  if both x and b are real respectively integer, y
% should also be
if isreal(x) && isreal(h)
  y = real (y);
end
if isinteger(x) && isinteger(h)
  y = round (y);
end

% Take just the first N elements
S.type='()';
for i=1:length(Ly)
  S.subs{i} = 1:Ly(i);
end
y=subsref(y,S);

if ~isempty(strfind(shape,'pad')) || ~isempty(strfind(shape,'extend'))
  y = padreplicate(y, -l);  % suppress padding from result
else
  A = x;
end

% reshape output as from convn and conv2
if (strfind(shape,'same'))
  sizeA = [size(A) ones(1,ndims(y)-ndims(A))];
  sizeB = [size(h) ones(1,ndims(y)-ndims(h))];
  flippedKernelCenter = ceil((1 + sizeB)/2);
  subs = cell(1,ndims(y));
  for p = 1:length(subs)
    subs{p} = (1:sizeA(p)) + flippedKernelCenter(p) - 1;
  end
  y = y(subs{:});

elseif (strfind(shape,'valid'))
  sizeB = [size(h) ones(1,ndims(y)-ndims(h))];
  outSize = max([size(A) ones(1,ndims(y)-ndims(A))] - sizeB + 1, 0);
  subs = cell(1,ndims(y));
  for p = 1:length(subs)
    subs{p} = (1:outSize(p)) + sizeB(p) - 1;
  end
  y = y(subs{:});

end

if transpose_x, y=y'; end

% return value

% ------------------------------------------------------------------------------
function b=padreplicate(a, padSize)
%Pad an array by replicating values.
numDims = length(padSize);
idx = cell(numDims,1);
for k = 1:numDims
  M = size(a,k);
  if padSize(k) > 0
    onesVector = ones(1,padSize(k));
    idx{k} = [onesVector 1:M M*onesVector];
  else
    idx{k} = [(1+abs(padSize(k))):(M-abs(padSize(k))) ];
  end
end

b = a(idx{:});
