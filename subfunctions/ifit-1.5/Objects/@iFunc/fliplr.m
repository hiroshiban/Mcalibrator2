function a = fliplr(a)
% b = fliplr(s) : Flip object in left/right direction
%
%   @iFunc/fliplr function to flip object in left/right direction
%     With 2D data sets, the X axis (horizontal) is inverted.
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=fliplr(a);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fliplr, fliplr, iFunc/flipud, flipud

a = iFunc_private_unary(a, 'fliplr');

