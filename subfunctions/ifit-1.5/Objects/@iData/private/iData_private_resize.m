function x = iData_private_resize(x,newsiz)

%RESIZE Resize any arrays and images.
%   Y = RESIZE(X,NEWSIZE) resizes input array X using a DCT (discrete
%   cosine transform) method. X can be any array of any size. Output Y is
%   of size NEWSIZE.
%   
%   Input and output formats: Y has the same class as X.
%
%   Note:
%   ----
%   If you want to multiply the size of an RGB image by a factor N, use the
%   following syntax: RESIZE(I,size(I).*[N N 1])
%
%   Examples:
%   --------
%     % Resize a signal
%     % original signal
%     x = linspace(0,10,300);
%     y = sin(x.^3/100).^2 + 0.05*randn(size(x));
%     % resized signal
%     yr = resize(y,[1 1000]);
%     plot(linspace(0,10,1000),yr)
%
%     % Upsample and downsample a B&W picture
%     % original image
%     I = imread('tire.tif');
%     % upsampled image
%     J = resize(I,size(I)*2);
%     % downsampled image
%     K = resize(I,size(I)/2);
%     % pictures
%     figure,imshow(I),figure,imshow(J),figure,imshow(K)
%
%     % Upsample and stretch a 3-D scalar array
%     load wind
%     spd = sqrt(u.^2 + v.^2 + w.^2); % wind speed
%     upsspd = resize(spd,[64 64 64]); % upsampled speed
%     slice(upsspd,32,32,32);
%     colormap(jet)
%     shading interp, daspect(size(upsspd)./size(spd))
%     view(30,40), axis(volumebounds(upsspd))
%
%     % Upsample and stretch an RGB image
%     I = imread('onion.png');
%     J = resize(I,size(I).*[2 2 1]);
%     K = resize(I,size(I).*[1/2 2 1]);
%     figure,imshow(I),figure,imshow(J),figure,imshow(K)
%
%   See also UPSAMPLE, RESAMPLE, IMRESIZE, DCTN, IDCTN
%
%   -- Damien Garcia -- 2009/11, revised 2010/01
%   website: <a
%   href='matlab:web('http://www.biomecardio.com')'>www.BiomeCardio.com</a>

error(nargchk(2,2,nargin));

siz = size(x);
N = prod(siz);

% Do nothing if size is unchanged
if isequal(siz,newsiz), return, end

% Check size arguments
assert(isequal(length(siz),length(newsiz)),...
    'Number of dimensions must not change.')
newsiz = round(newsiz);
assert(all(newsiz>0),'Size arguments must be >0.')

class0 = class(x);
is01 = islogical(x);


% DCT transform
x = dctn(x);

% Crop the DCT coefficients
for k = 1:ndims(x)
    siz(k) = min(newsiz(k),siz(k));
    x(siz(k)+1:end,:) = [];
    x = reshape(x,circshift(siz,[0 1-k]));
    x = shiftdim(x,1);
end

% Pad the DCT coefficients with zeros
x = padarray(x,max(newsiz-siz,zeros(size(siz))),0,'post');

% inverse DCT transform
x = idctn(x)*sqrt(prod(newsiz)/N);

% Back to the previous class
if is01, x = round(x); end
x = cast(x,class0);



% ------------------------------------------------------------------------------
function B = padarray(A, padsize, padval, direction)
  % Check parameters
  if nargin < 3, padval = 0; end
  if nargin < 4, direction='both'; end

  if (~isvector(padsize) || ~isnumeric(padsize) || any(padsize < 0) || any(padsize ~= round(padsize)))
    error('padarray: padsize must be a vector of positive integers.');
  end
  if (~isscalar(padval) && ~ischar(padval))
    error('padarray: third input argument must be a string or a scalar');
  end
  if (~ischar(direction) || ~any(strcmpi(direction, {'pre', 'post', 'both'})))
    error('padarray: fourth input argument must be "pre", "post", or "both"');
  end

  %% Assure padsize is a row vector
  padsize = padsize(:).';

  % Check direction
  pre  = any(strcmpi(direction, {'pre', 'both'}));
  post = any(strcmpi(direction, {'post', 'both'}));
  
  B = A;
  dim = 1;
  for s = padsize
    if (s > 0)
      % padding in this dimension was requested
      ds = size(B);
      ds = [ds, ones(1,dim-length(ds))]; % data size
      ps = ds;
      ps(dim) = s;		       % padding size

      if (ischar(padval))
	% Init a 'index all' cell array. All cases need it.
	idx = cell(1, length(ds));
	for i = 1:length(ds)
	  idx{i} = 1:ds(i);
	end

	switch (padval)
	  case ('circular')
	    complete = 0;
	    D = B;
	    if (ps(dim) > ds(dim))
	      complete = floor(ps(dim)/ds(dim));
	      ps(dim) = rem(ps(dim), ds(dim));
	    end
	    if (pre)
	      for i = 1:complete
		B = cat(dim, D, B);
	      end
	      idxt = idx;
	      idxt{dim} = ds(dim)-ps(dim)+1:ds(dim);
	      B = cat(dim, D(idxt{:}), B);
	    end
	    if (post)
	      for i = 1:complete
		B = cat(dim, B, D);
	      end
	      idxt = idx;
	      idxt{dim} = 1:ps(dim);
	      B = cat(dim, B, D(idxt{:}));
	    end
	    % end circular case

	  case ('replicate')
	    if (pre)
	      idxt = idx;
	      idxt{dim} = 1;
	      pad = B(idxt{:});
	      % can we do this without the loop?	
	      for i = 1:s
		B = cat(dim, pad, B);
	      end
	    end
	    if (post)
	      idxt = idx;
	      idxt{dim} = size(B, dim);
	      pad = B(idxt{:});
	      for i = 1:s
		B = cat(dim, B, pad);
	      end
	    end
	    % end replicate case
	
	  case ('symmetric')
	    if (ps(dim) > ds(dim))
	      error('padarray: padding is longer than data using symmetric padding');
	    end
	    if (pre)
	      idxt = idx;
	      idxt{dim} = ps(dim):-1:1;
	      B = cat(dim, B(idxt{:}), B);
	    end
	    if (post)
	      idxt = idx;
	      sbd = size(B, dim);
	      idxt{dim} = sbd:-1:sbd-ps(dim)+1;
	      B = cat(dim, B, B(idxt{:}));
	    end
	    % end symmetric case

	  case ('reflect')
	    if (ps(dim) > ds(dim)-1)
	      error('padarray: padding is longer than data using "reflect" padding');
	    end
	    if (pre)
	      idxt = idx;
	      idxt{dim} = (ps(dim):-1:1) + 1;
	      B = cat(dim, B(idxt{:}), B);
	    end
	    if (post)
	      idxt = idx;
	      sbd = size(B, dim)-1;
	      idxt{dim} = sbd:-1:sbd-ps(dim)+1;
	      B = cat(dim,B,B(idxt{:}));
	    end
	    % end reflect case

	  otherwise
	    error('padarray: invalid string in padval parameter.');

	end
	% end cases where padval is a string

      elseif (isscalar(padval))
	% Handle fixed value padding
	if (padval == 0)
	  pad = zeros(ps, class(A));       %% class(pad) = class(A)
	else
	  pad = padval*ones(ps, class(A)); %% class(pad) = class(A)
	end
	if (pre && post)
	  % check if this is not quicker than just 2 calls (one for each)
	  B = cat(dim, pad, B, pad);
	elseif (pre)
	  B = cat(dim, pad, B);
	elseif (post)
	  B = cat(dim, B, pad);
	end
      end
    end
    dim = dim+1;
  end

