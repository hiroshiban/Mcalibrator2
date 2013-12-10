function b = ifft(a, varargin)
% c = ifft(a) : computes the inverse Discrete Fourier transform of iData objects
%
%   @iData/ifft function to compute the inverse Discrete Fourier transform of data sets
%     using the FFT algorithm.
%
% input:  a: object or array (iData)
% output: c: object or array (iData)
% ex:     t=linspace(0,1,1000); 
%         a=iData(t,0.7*sin(2*pi*50*t)+sin(2*pi*120*t)+2*randn(size(t)));
%         c=fft(a); d=ifft(c); plot([ a d ])
%
% Version: $Revision: 1035 $
% See also iData, iData/fft, iData/conv, FFT, IFFT

b = fft(a, 'ifft', varargin{:});

