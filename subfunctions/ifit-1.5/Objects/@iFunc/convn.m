function c = convn(a,b)
% c = convn(a,b) : computes the convolution of an iFunc object with a response function 
%
%   @iData/convn function to compute the convolution of data sets with automatic centering
%     and normalization of the filter. This is a shortucut for
%       conv(a,b, 'same pad background center normalize')
%     When used with a single scalar value, it is used as a width to build a 
%       gaussian function.
%     when one of the argument is a character string, it is used as-is in the 
%     operator expression. 
%
% input:  a: object or array, signal (iFunc or numeric)
%         b: object or array, filter (iFunc or numeric)
% output: c: object or array (iFunc)
% ex:     c=convn(a,b);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/times, iData/convn, iFunc/xcorr, fconv, fconvn, fxcorr
if nargin ==1
	b=a;
end
c = conv(a, b, 'same pad background center normalize');


