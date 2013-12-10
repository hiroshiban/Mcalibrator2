function [match, field] = strfind(s, varargin)
% [match, field]=strfind(s, pattern, option) : search for pattern in iData
%
%   @iData/strfind function to look for patterns stored in iData
%
%   [match,field] = findfstr(iData, pattern) returns the string containg 'str' 
%     and the field name it appears in. If 'pattern' is set to '', the content of all
%     character fields is returned.
%   The 'option' may contain 'exact' to search for the exact occurence, and 'case'
%   to specifiy a case sensitive search.
%
% input:  s: object or array (iData)
%         pattern: string to search in object, or '' (char).
%         option: 'exact' 'case' or '' (char)
% output: match: content of iData fields that contain 'str' (cellstr)
%         field: name of iData fields that contain 'str' (cellstr)
% ex:     strfind(iData,'ILL') or strfind(s,'TITLE','exact case')
%
% Version: $Revision: 1035 $
% See also iData, iData/set, iData/get, iData/findobj, iData/findfield

% EF 23/09/07 iData implementation

[match, field] = findstr(s, varargin{:});
