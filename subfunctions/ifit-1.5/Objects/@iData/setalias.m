function this = setalias(this,names,links,labels)
% [s,...] = setalias(s, AliasName, AliasLink, {AliasLabel}) : set iData aliases
%
%   @iData/setalias function to set iData aliases.
%   The function works also when AliasName, AliasLink, and optional AliasLabel
%     are given as cell strings. The AliasLink may be of any class, but char is
%     interpreted as a link to search in the object or an external file, such
%     as '#Data' 'Data' (local links), 'file://path' (full file structure)
%     or 'file://path#Data' (a part of an external file).
%   The special name 'this' may be used in the Alias link to refer the object itself.
%   When the link is empty, the alias is removed, so that
%     setalias(s, alias)       deletes an alias, similarly to rmalias
%     setalias(s, getalias(s)) deletes all alias definitions.
%   The command setalias(iData,'Signal') sets the Signal to the biggest numerical field.
%   The input iData object is updated if no output argument is specified.
%   An new field/alias may be defined with the quick syntax 's.alias = value'.
%
% input:  s: object or array (iData)
%         AliasName: Name of existing or new alias (char/cellstr)
%         AliasLink: definition of the alias, or '' to remove the alias (cell of char/double/...)
%         AliasLabel: optional description/label of the alias (char/cellstr)
% output: s: array (iData)
% ex:     setalias(iData,'Temperature','Data.Temperature','This is the temperature')
%         setalias(iData,'Temperature','this.Data.Temperature')
%         setalias(iData,'Temperature',1:20)
%         setalias(iData,'T_pi','[ this.Data.Temperature pi ]')
%
% Version: $Revision: 1035 $
% See also iData, iData/getalias, iData/get, iData/set, iData/rmalias

% EF 27/07/00 creation
% EF 23/09/07 iData implementation

persistent fields

if isempty(fields), fields=fieldnames(iData); end

s_out=this;
if nargin == 1
  % makes a check of aliases, Signal, Error, Monitor, warns invalid ones.
  for index = 1:numel(this)
    a = this(index); % current object in array/single element
    for j1=1:length(a.Alias.Names)
      try
        get(a, a.Alias.Names{j1});
      catch
        v = a.Alias.Values{j1};
        if isnumeric(v), v = mat2str(v(1:min(20,length(v))));
        else             v = class(v);
        end
        iData_private_warning(mfilename,[ 'the Alias ' a.Alias.Names{j1} '=' v ' is not valid in object ' inputname(1) ' ' a.Tag ' "' a.Title '".' ]);
      end
    end
  end
  return
elseif nargin == 2
  names = cellstr(names);
  if length(names) == 1 && strcmp(names{1}, 'Signal')
    this.Alias.Values{1}='';
    this = iData(this);  % check the object
    if nargout == 0 & ~isempty(inputname(1))
      assignin('caller',inputname(1),this);
    end
    return
  end
  links = ''; labels=''; % removes aliases
  if length(this.Alias.Names) >= 4
    names = this.Alias.Names(4:end);
  end
elseif nargin == 3
  labels='';
end

if isempty(names), return; end

% handle array of objects
if numel(this) > 1
  parfor index=1:numel(this)
    this(index) = setalias(this(index), names, links, labels);
  end
  if nargout == 0 && ~isempty(inputname(1)) % update array inplace
    assignin('caller', inputname(1), this);
  end
  return
end

if any(strcmp('Signal',names)) && isempty(links)
  % reset Signal to the default largest numerical field
  this.Alias.Values{1} = '';
  this = iData(this);
  if nargout == 0 & ~isempty(inputname(1))
    assignin('caller',inputname(1),this);
  end
  return
end

names = cellstr(names);

if  ischar(links), links = cellstr(links); end
if ~iscell(links), links = { links }; end

labels= cellstr(labels);

if numel(this)
  to_keep = [ this.Alias.Names(1:3) this.Alias.Values(1:3) this.Alias.Axis ];
else
  to_keep = [];
end

% handle single object
for index=1:length(names) % loop on alias names
  name = names{index};
  if length(links) == length(names), link = links{index}; else link=''; end
  if length(labels)== length(names), label= labels{index}; else label=''; end
  
  % check that name is not a class member
  if strcmpi(name, fields)
    iData_private_warning(mfilename,[ 'the Alias ' name ' is a protected name in object ' inputname(1) ' ' this.Tag ' "' this.Title '".' ]);
    continue
  end
  % check if the alias name is not a file name/link
  if (strncmp(name, 'http://', length('http://'))  || ...
      strncmp(name, 'https://',length('https://')) || ...
      strncmp(name, 'ftp://',  length('ftp://'))   || ...
      strncmp(name, 'file://', length('file://'))  || ...
     (~isempty(name) && name(1) == '#') )
    continue;
  end
  alias_num   = find(strcmpi(name, this.Alias.Names)); % usually a single match
  if isempty(link) && any(alias_num <= 3) 
    % set Signal, Error, Monitor to empty (default)
    this.Alias.Values{alias_num} = [];
    this.Alias.Labels{alias_num} = [];
  elseif isempty(link) && any(alias_num > 3) % protect Signal, Error, Monitor
    % remove these aliases from Alias list
    % first check that we will not remove something important: Axes, Signal, ...
    if any(strcmp(this.Alias.Names{alias_num}, to_keep)), continue; end

    this.Alias.Names(alias_num)  = [];
    this.Alias.Values(alias_num) = [];
    this.Alias.Labels(alias_num) = [];
  elseif ~isempty(link)
    % update or add alias
    if isempty(alias_num) && ~strcmp(name, link) % add
      this.Alias.Names{end+1} = name;
      this.Alias.Values{end+1}= link;
      this.Alias.Labels{end+1}= regexprep(label,'\s+',' ');
    else
      % check Error and Monitor values
      if isnumeric(link) && (alias_num == 2 || alias_num == 3) % Error,Monitor
        if all(link(:) == link(end))
          link = link(end);
        end
      end
      this.Alias.Names{alias_num} = name;
      if ~isempty(link) || isempty(label),                       this.Alias.Values{alias_num}= link; end
      if ~isempty(label)|| isempty(this.Alias.Labels{alias_num}),this.Alias.Labels{alias_num}= label; end
    end
  end
end % for alias names
this = iData_private_history(this, mfilename, this, name, link, label);


if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),this);
end
