function s=str2struct(string)
% s=str2struct(string) Create a structure from string lines
%   This function creates a structure from string containing <name> <value> pairs
%   Structure member must be separated by ';' or end-of-lines.
%   The member assignation can be specified with spaces, '=' and ':'
%
% input arguments:
%   string: string from which the structure should be extracted. It can
%           also be a file name, which is then read.
%
% output variables:
%   s: structure which contains the named values
%
% example: str=str2struct('Temperature: 200; RV=3; comment something nice');
%          
% See also: mat2str, num2str, eval, sprintf, class2str
%
% Part of: Loaders utilities (ILL library)
% Author:  E. Farhi <farhi@ill.fr>. $Revision: 1102 $

s={};
if nargin ==0, return; end
if isempty(string), return; end

if ischar(string) && exist(string, 'file')
  fid=fopen(string); 
  string=fread(fid, Inf); fclose(fid);
  string=char(string');
  string(find(string=='$' | string=='#')) = '';
end
if ~ischar(string) && ~iscell(string), return; end

% transform the string into a cellstr
string = cellstr(string);

cellstring = {};

% split the string into seperate lines if they contain <EOL> characters
for index=1:numel(string)
  this = string{index};
  split = textscan(this,'%s','Delimiter',sprintf('\n\r\f;'));
  for j=1:numel(split)
    this_split=split{j};
    cellstring = { cellstring{:} this_split{:} };
  end
end

% interpret the line as <name> <separator> <value> <comment>
for index=1:numel(cellstring)
  this = cellstring{index};
  [name, value] = str2struct_value_pair(this);
  if ~isempty(name) && ~isempty(value) 
    if ~isstruct(value), s.(name) = value; 
    else
      f = fieldnames(value);
      s.(name).(f{1}) = value.(f{1});
    end
  end
end

% ==============================================================================
function [name, value] = str2struct_value_pair(this)
  % split token 'this' as name=value
  [name, line] = strtok(this, sprintf('=: \t'));
  value = [];
  if isempty(name), return; end
  if name(1)=='#' || name(1)=='%' || strncmp(name, '//', 2) || name(1) == '!'
    name=[]; % skip comment lines
    return
  end
  nextline = min(find(isstrprop(line, 'alphanum')));
  startline=line(1:nextline);
  nextline=max(find(startline == '=' | startline == ' ' | startline == ':'));
  if   nextline >= 1, nextline=nextline+1; 
  else name = []; return; end
  line = line(nextline:end);
  % extract numerical value after the starting token 'name'
  [value, count, errmsg, nextindex] = sscanf(line, '%f');
  comment = strtrim(line(nextindex:end)); comment(~isstrprop(comment,'print')) = ' ';
  name = strrep(name, '.', '_');
  name = strrep(name, '-', '_');
  name = genvarname(name);
  % handle case where line starts with a number not separated from
  % following text
  if nextindex <= length(line) &&  ~isspace(line(nextindex))
    value = line; % then a char
  end
  % when value can not be obtained, try with num2str (for expressions)
  if isempty(value), 
    value=comment;
    tmp  =str2num(value);
    if ~isempty(tmp) && isnumeric(tmp)
      value=tmp;
    end
    if ischar(value)
      % check if the 'value' as char starts/ends with quotes
      if value(1) == '''' || value(1) == '"'
        value = value(2:end);
        if value(end) == '''' || value(end) == '"'
          value = value(1:(end-1));
        end
      else
        % check again if value contains itself an assignement
        if ~isempty(find(value == '='))
          [n,v] =  str2struct_value_pair(value);
          if ~isempty(n) && ~isempty(v)
            s.(n) = v;
            value = s;
          end
        end
      end
    end
  end

