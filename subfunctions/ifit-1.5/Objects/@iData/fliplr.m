function a = fliplr(a)
% b = fliplr(s) : Flip object in left/right direction
%
%   @iData/fliplr function to flip object in left/right direction
%     With 2D data sets, the X axis (horizontal) is inverted.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=fliplr(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/fliplr, fliplr, iData/flipud, flipud

a = iData_private_unary(a, 'fliplr');

