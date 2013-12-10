function [ret, header] = char(s)
% ret = char(s) : convert iFunc into character
%
%   @iFunc/char: function to convert iFunc objects into char
%   returns the iFunc expression to evaluate
%
% input:  s: object or array (iFunc) 
% output: ret: iFunc identification (char)
%
% Version: $Revision: 1035 $
% See also  iFunc/struct, iFunc/char
%


ret=[];
if numel(s) > 1
  ret = {};
  for index=1:numel(s)
    ret{index} = char(s(index));
  end
  return
end
  
[ret, header] = cellstr(s);
ret = char(ret); % as a single char line
