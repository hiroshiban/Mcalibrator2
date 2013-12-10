function a = diff(a)
% b = diff(s) : computes the difference long 1st axis of iData object
%
%   @iData/diff function to compute the difference along rows, that is the 
%     gradient for the 1st axis (rows).
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=diff(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/gradient, iData/sum, iData/trapz, iData/jacobian

a = gradient(a, 1);

