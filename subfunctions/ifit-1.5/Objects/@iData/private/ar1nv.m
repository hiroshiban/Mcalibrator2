function [g,a]=ar1nv(x)
% AR1NV - Estimate the parameters for an AR(1) model 
% Syntax: [g,a]=ar1nv(x);
%
% Input: x - a time series.
%
% Output: g - estimate of the lag-one autocorrelation.
%         a - estimate of the noise variance.

%  Cross wavelet and wavelet coherence package  (pre-release 1)
%  by Aslak Grinsted, John Moore and Svetlana Jevrejeva
%  ----------------------------------------------------
%
%  Please notice that most of the routines included in this package has the following license. 
%
%  This software may be used, copied, or redistributed as long as it is not sold and this copyright notice is reproduced on each copy made. This routine is provided as is without any express or implied warranties whatsoever.
%
%  However, not all the routines are published under these terms, and before redistributing them in any form we advise you to ask permission from the authors.
%
%  Acknowledgements
%  We would like to thank the following people for letting us include their programs in our package.
%
%  Torrence and Compo for CWT software. A Practical Guide to Wavelet Analysis 
%  Eric Breitenberger for AR1 and AR1Noise. 
%  Eric A. Johnson for Arrow.m. 
%  Blair Greenan for Colorbarf.m 

x=x(:);
N=length(x);
m=mean(x);
x=x-m;
 
% Lag zero and one covariance estimates:
c0=x'*x/N;
c1=x(1:N-1)'*x(2:N)/(N-1);

g=c1/c0;
a=sqrt((1-g^2)*c0);
