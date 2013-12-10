function [match, field] = findstr(s, str, option)
% [match, field]=findstr(s, str, option) : look for strings stored in iData
%
%   @iData/findstr function to look for strings stored in iData
%
%   [match,field] = findstr(iData, str) returns the string containg 'str' 
%     and the field name it appears in. If 'str' is set to '', the content of all
%     character fields is returned.
%   The 'option' may contain 'exact' to search for the exact occurence, and 'case'
%   to specifiy a case sensitive search.
%
% input:  s: object or array (iData)
%         str: string to search in object, or '' (char or cellstr).
%         option: 'exact' 'case' or '' (char)
% output: match: content of iData fields that contain 'str' (cellstr)
%         field: name of iData fields that contain 'str' (cellstr)
% ex:     findstr(iData,'ILL') or findstr(s,'TITLE','exact case')
%
% Version: $Revision: 1166 $
% See also iData, iData/set, iData/get, iData/findobj, iData/findfield

% EF 23/09/07 iData implementation

if nargin == 1
  str='';
end
if nargin <= 2
  option='';
end

if numel(s) > 1
  match = cell(1, numel(s)); field=match;
  parfor index=1:numel(s)
    [m,f] = findstr(s(index), str, option);
    match{index}=m;
    field{index}=f;
  end
  return
end

[fields, types] = findfield(s,'','char');  % get all fields and types

index=[ find(strcmp('char', types)) ; find(strcmp('cell', types)) ]; 
if isempty(index), field=[]; match=[]; return; end

clear types
% get all field names containg char/cellstr data
fields = fields(index); 
% get their content
matchs = get(s, fields);
% convert to char using private inline function handle
matchs = cellfun(@cell2char, matchs, 'UniformOutput', false);

if isempty(str)
  match = matchs;
  field = fields;
  return
end

if iscell(str) && ischar(str{1})
  match = cell(1, numel(str)); field=match;
  for index=1:numel(str)
    [m,f] = iData_findstr_single(str{index}, option, fields, matchs);
    match{index}=m;
    field{index}=f;
  end
  return
end

[match, field] = iData_findstr_single(str, option, fields, matchs);

% -------------------------------------------------------------------------
function [match, field] = iData_findstr_single(str, option, field, match)

% search for the string
if strfind(option, 'exact')
  % handle 'exact' option
  index = strcmp(match, str);
elseif strfind(option, 'case')
  % handle 'case' option
  index = ~cellfun(@isempty, strfind(match, str));
else
  % relaxed search: non case sensitive, find token (not exact comparison)
  index = ~cellfun(@isempty, strfind(lower(match), lower(str)));
end
match = match(index);
field = field(index);

if numel(field) == 1, field=field{1}; end
if numel(match) == 1, match=match{1}; end

% -------------------------------------------------------------------------
function c=cell2char(c)
if iscell(c) && ischar(c{1})
    c=char(c);
elseif ~ischar(c)
    c = '';
end
