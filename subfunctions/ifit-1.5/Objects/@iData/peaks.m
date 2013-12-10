function [sigma, position, amplitude, baseline] = peaks(a, dim, m)
% [half_width, center, amplitude, baseline] = peaks(s, dim, m) : peak position and width of iData
%
%   @iData/peaks function to compute an estimate of peak position and width along
%     dimension 'dim'
%
% input:  a: object or array (iData/array of)
%         dim: dimension to use. Default is 1 (int)
%         m: typical peak width or 0 for automatic guess (int)
% output: half_width: width of peaks (scalar/array)
%         center:     center of peaks (scalar/array)
%         amplitude:  amplitude of peaks (scalar/array)
%         baseline:   baseline (background) (iData)
% ex:     c=peaks(a);
%
% References: Slavic, NIM 112 (1973) 253 ; M. Morhac, NIM A 600 (2009) 478 
%
% Version: $Revision: 1035 $
% See also iData, iData/median, iData/mean, iData/std

% inline functions: BaseLine, PeakWidth

  if nargin < 2, dim=1; end
  if nargin < 3, m=0; end
  if numel(a) > 1
    sigma = cell(size(a)); position = sigma; amplitude = sigma; baseline = sigma;
    parfor index=1:numel(a)
      [si, fi, ai, bi] = peaks(a(index), dim, m);
      sigma{index}     = si;
      position{index}  = fi;
      amplitude{index} = ai;
      baseline{index}  = bi;
    end
    return
  end

  if dim == 0 || abs(dim) > prod(ndims(a))
    dim = 1;
  end

  % we first compute projection of iData on the selected dimension
  if ndims(a) > 1 && ~isvector(a)
    b = camproj(a, abs(dim));
  else
    b = copyobj(a);
  end

  % then we compute sum(axis{dim}.*Signal)/sum(Signal)
  
  % first we make sure the axis is regularly sampled
  x = getaxis(b,1);
  dx= abs(diff(x)); dx=dx(dx ~= 0);
  new_x      = min(x):min(dx):max(x);
  b = interp(b, new_x);
  signal = iData_private_cleannaninf(get(b,'Signal')); 
  signal = signal(:);
  baseline = BaseLine(signal, m);

  sigma = PeakWidth(signal-baseline, m)*min(diff(new_x));

  % now find max position and amplitude for each peak
  % shift one step aside
  Gmm = circshift(signal, -1); Gmm((end-1):end) = 0;
  Gpm = circshift(signal,  1); Gpm(1) = 0; 
  % a Max is such that Gmm < signal & Gpm < signal
  index = find(Gmm < signal & Gpm < signal & sigma > 4*min(diff(new_x)) & signal-baseline > 0.2*signal);
  if isempty(index)
    index = find( Gmm <= signal & Gpm <= signal & sigma > 4*min(diff(new_x)) );
  end
  
  if numel(index) <= 1
    sum_s = sum(signal); x1d=1:length(signal); x1d=x1d(:);
    % first moment (mean)
    f = sum(signal.*x1d)/sum_s; % mean value
    % second moment: sqrt(sum(x^2*s)/sum(s)-fmon_x*fmon_x);
    s = sqrt(sum(x1d.*x1d.*signal)/sum_s - f*f);
    f = round(f);
    if     f < 1,             f=1; 
    elseif f > length(new_x), f=length(new_x); 
    end
    position=new_x(f);
    sigma   =s/2*min(diff(x));
    if ~isreal(sigma)
      sigma = std(x1d);
    end
    amplitude=max(signal)-min(signal);
    baseline =ones(size(signal))*min(signal);
  else
    position  = new_x(index);
    amplitude = signal(index);
    sigma     = sigma(index); 
  end
  
  set(b, 'Signal', baseline);
  baseline  = b; 
end

% ==============================================================================
% inline functions: BaseLine, PeakWidth
% ==============================================================================
function baseline = BaseLine(y, m)
% BaseLine: compute signal baseline from: M. Morhac, NIM A 600 (2009) 478
% computes baseline estimate along signal 'y' of given length 'n'
% with contrast parameter 'm' (see paper above).

  baseline = [];
  if nargin == 1, m=0; end
  if (m<=0) m=ceil(max(5, length(y)/50)); end % automatic largest width estimate
  if (length(y)<=m) return; end
  
  % improved from 'Algorithm C' from M. Morhac, NIM A 600 (2009) 478
  baseline=y;
  shifts = zeros(m+1, length(y)-m);
  new_length=length(y)-m;
  for i=0:m;
    shifts(i+1, :) = y((i+1):(i+new_length));
  end
  shifts = min(shifts);
  i = ceil(m/2);
  baseline((i+1):(i+new_length)) = shifts;
end

function sigma = PeakWidth(signal, m) 
% PeakWidth: estimate peak width from: M. Morhac, NIM A 600 (2009) 478
% computes peak width estimate sigma along signal of given length
% with contrast parameter 'm' (see paper above).
% the peak width is given in bins.

  sigma = [];
  sz = size(signal);
  signal = signal(:);
  if nargin == 1, m=0; end
  
  if (m<1) m=ceil(max(5, length(signal)/50)); end
  if length(signal) < 4*m, m=3; end
  if (length(signal)<=m) return; end
  
  % Gaussian product function as of Slavic, NIM 112 (1973) 253 
  Gmm = circshift(signal, -m); Gmm((end-m):end) = 0;
  Gpm = circshift(signal,  m); Gpm(1:m) = 0; 
  
  sigma = ones(sz)*max(signal);
  index = find(Gmm < signal & Gpm < signal & Gmm~=0 & Gpm~=0);
  sigma(index) = signal(index).*signal(index)./Gmm(index)./Gpm(index);
  index= find(sigma>1);
  sigma(index) = m./sqrt(log(sigma(index)));
  sigma = reshape(sigma, sz);
end
