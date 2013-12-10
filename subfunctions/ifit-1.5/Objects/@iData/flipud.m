function a = flipud(a)
% b = flipud(s) : Flip object in up/down direction
%
%   @iData/flipud function to flip object in up/down direction
%     With 2D data sets, the Y axis (vertical) is inverted.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=flipud(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/fliplr, fliplr, iData/flipud, flipud

a = iData_private_unary(a, 'flipud');

