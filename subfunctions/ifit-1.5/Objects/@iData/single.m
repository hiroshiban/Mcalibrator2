function a=single(a)
% d = single(s) : convert iData into single floats
%
%   @iData/double function to convert iData object into single floats
%
% input:  s: object or array (iData)
% output: v: value of the iData Signal/Monitor (single)
% ex:     'single(iData(rand(10)))'
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
  return
end

a = get(a, 'Signal');
a = single(a);

