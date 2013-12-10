function [sigma, position, amplitude, baseline] = iFunc_private_findpeaks(signal, dim, m)
% [half_width, center, amplitude, baseline] = iFunc_private_findpeaks(s, dim, m) : find peak position and width of signal
%
%   findpeaks private function to compute an estimate of peak position and width along
%     dimension 'dim'
%
% input:  a: signal array (double)
%         dim: dimension to use. Default is 1 (int)
%         m: typical peak width or 0 for automatic guess (int)
% output: half_width: width of peaks (scalar/array)
%         center:     center index of peaks (scalar/array)
%         amplitude:  amplitude of peaks (scalar/array)
%         baseline:   baseline (background) (iData)
%
% Version: $Revision: 1035 $

% inline functions: BaseLine, PeakWidth

  if nargin < 2, dim=1; end
  if nargin < 3, m=0;   end

  if dim == 0 || abs(dim) > prod(ndims(signal))
    dim = 1;
  end

  % we first compute projection of signal on the selected dimension
  if ~isvector(signal)
    for index=ndims(signal):1
      if index~= dim
        signal= trapz(signal, index);
      end
    end
  end

  % then we compute sum(axis{dim}.*Signal)/sum(Signal)
  signal   = signal(:);
  baseline = BaseLine(signal, m);
  sigma    = PeakWidth(signal-baseline, m);

  % now find max position and amplitude for each peak
  % shift one step aside
  Gmm = circshift(signal, -1); Gmm((end-1):end) = 0;
  Gpm = circshift(signal,  1); Gpm(1) = 0; 
  % a Max is such that Gmm < signal & Gpm < signal
  index = find(Gmm < signal & Gpm < signal & sigma > 4 & signal-baseline > 0.2*signal);
  if isempty(index)
    index = find(Gmm <= signal & Gpm <= signal & sigma > 1);
  end
  if isempty(index)
    index = find(Gmm <= signal & Gpm <= signal);
  end
  
  position  = index;
  amplitude = signal(index);
  sigma     = sigma(index);
end % iFunc_private_findpeaks

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
  if length(signal) <= m, return; end
  
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
