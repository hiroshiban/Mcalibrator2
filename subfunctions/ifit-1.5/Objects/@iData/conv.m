function c = conv(a,b, shape)
% c = conv(a,b) : computes the convolution of iData objects
%
%   @iData/conv function to compute the convolution of data sets (FFT based).
%     A deconvolution mode is also possible.
%     When used with a single scalar value, it is used as a width to build a 
%       gaussian function.
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric or scalar)
%     shape: optional shape of the return value
%          full         Returns the full two-dimensional convolution.
%          same         Returns the central part of the convolution of the same size as a.
%          valid        Returns only those parts of the convolution that are computed
%                       without the zero-padded edges. Using this option, y has size
%                       [ma-mb+1,na-nb+1] when all(size(a) >= size(b)).
%          deconv       Performs an FFT deconvolution.
%          pad          Pads the 'a' signal by replicating its starting/ending values
%                       in order to minimize the convolution side effects
%          center       Centers the 'b' filter so that convolution does not shift
%                       the 'a' signal.
%          normalize    Normalizes the 'b' filter so that the convolution does not
%                       change the 'a' signal integral.
%          background   Remove the background from the filter 'b' (subtracts the minimal value)
%     Default shape is 'same'
%
% output: c: object or array (iData)
% ex:     c=conv(a,b); c=conv(a,b, 'same pad background center normalize');
%
% Version: $Revision: 1113 $
% See also iData, iData/times, iData/convn, iData/fft, iData/xcorr, fconv, fconvn, fxcorr
if nargin ==1
	b = a;
end
if nargin < 3, shape = 'same'; end
if isscalar(b)
  b = [ 1 mean(getaxis(a,1)) double(b) 0]; % use input as a width
  b = gauss(b, getaxis(a,1));
  c = conv(a,b,[ shape ' normalize' ]);
  return
elseif isscalar(a)
  a = [ 1 mean(getaxis(b,1)) double(a) 0]; % use input as a width
  a = gauss(a, getaxis(b,1));
  c = conv(a,b,[ shape ' normalize' ]);
  return
end

c = iData_private_binary(a, b, 'conv', shape);

