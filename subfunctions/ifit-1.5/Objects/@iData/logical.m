function a=logical(a)
% d = logical(s) : convert iData into logical array
%
%   @iData/logical function to convert iData object into logical (1/0)
%
% input:  s: object or array (iData)
% output: v: value of the iData Signal (logical)
% ex:     'logical(iData(rand(10)))'
%
% Version: $Revision: 1035 $
% See also  iData/cell, iData/double, iData/struct, 
%           iData/char, iData/size

% EF 11/07/00 creation
% EF 23/09/07 iData implementation

if numel(a) > 1
  b = cell(size(a));
  parfor index=1:numel(a)
    b{index} = feval(mfilename, a(index));
  end
  a = b;
  return
end

a = iData_private_cleannaninf(get(a, 'Signal'));
a = logical(a);
