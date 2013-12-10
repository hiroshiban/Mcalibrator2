function [content,fields]=cell(s)
% [content,fields]=cell(s) : convert iData objects into cells
%
%   @iData/cell function to convert iData objects into cells
%
% input:  s: iData single object (iData)
% output: content: content of the iData structure (cell)
%         fields:  field names of the iData object (cell)
%
% Version: $Revision: 1057 $
% See also  iData/cell, iData/double, iData/struct, 
%           iData/char, iData/size

% EF 27/07/00 creation
% EF 23/09/07 iData implementation

persistent field

if isempty(field), field=fieldnames(iData); end
fields=field;

if length(s(:)) > 1
  iData_private_warning(mfilename, ['I can not handle iData arrays. ' inputname(1) ' size is [' num2str(size(s)) ']. Using first array element.']);
  s = s(1);
end

content = struct2cell(s);
