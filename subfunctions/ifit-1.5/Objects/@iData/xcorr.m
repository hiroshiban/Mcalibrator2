function c = xcorr(a,b, shape)
% c = xcorr(a,b) : computes the correlation of iData objects
%
%   @iData/xcorr function to compute the correlation of data sets (FFT based).
%     A decorrelation mode is also possible. When only one argument is given, 
%     the auto-correlation is computed.
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
%     shape: optional shape of the return value
%          full         Returns the full two-dimensional correlation.
%          same         Returns the central part of the correlation of the same size as a.
%          valid        Returns only those parts of the correlation that are computed
%                       without the zero-padded edges. Using this option, y has size
%                       [ma-mb+1,na-nb+1] when all(size(a) >= size(b)).
%          pad          Pads the 'a' signal by replicating its starting/ending values
%                       in order to minimize the correlation side effects
%          center       Centers the 'b' filter so that correlation does not shift
%                       the 'a' signal.
%          normalize    Normalizes the 'b' filter so that the correlation does not
%                       change the 'a' signal integral.
%          background   Remove the background from the filter 'b' (subtracts the minimal value)
%     Default shape is 'same center'
%
% output: c: object or array (iData)
% ex:     c=xcorr(a,b); c=xcorr(a,b, 'same pad background center normalize');
%
% Version: $Revision: 1113 $
% See also iData, iData/times, iData/convn, iData/fft, convn, fconv, fconvn
if nargin ==1
	b = a;
end
if nargin < 3, shape = 'same center'; end

c = conv(a, b, [ shape ' correlation' ]);

