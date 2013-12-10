function y=fconvn(x, h)
%FCONVN Fast Convolution with nomalization and centering of the filter.
%   y = FCONVN(x, h) convolves x and h.
%   It works with x and h being of any dimensionality. When only one argument is given, 
%     the auto-convolution is computed.
%   This is the same as calling 
%     fconv(x,h, 'same pad background center normalize');
%
%      x = input vector (signal)
%      h = input vector (filter)
%
% ex:     c=fconvn(a,b);
%
%      See also FCONV, FXCORR, CONV, CONV2, FILTER, FILTER2, FFT, IFFT
%
% Version: $Revision: 1035 $
y=fconv(x,h, 'same pad background center normalize');
