function a=find(a)
% d = find(s) : find iData signal non zeros values
%
%   @iData/find function to find iData non zeros values
%
% input:  s: object or array (iData)
% output: v: value of the iData Signal (logical)
% ex:     'find(iData(rand(10)))'
%
% Version: $Revision: 1035 $
% See also  iData/find, iData

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

a = get(a, 'Signal');
a = find(a);
