function [link, label, names] = getalias(this,alias)
% [link, label,names] = getalias(s, 'AliasName') : get iData alias
%
%   @iData/getalias function to get iData alias definition.
%   [link, label]          = getalias(s, alias) returns the alias link and its label/description.
%   [names, links, labels] = getalias(s)        returns all defined aliases.
%   The Signal, Error and Monitor aliases are always defined.
%   The value of the alias is obtained with the syntax: 's.alias'.
%   To search for aliases/fields in the object you may use findfield.
%
% input:  s: object or array (iData)
%         alias: alias name to inquire in object, or '' (char).
% output: link: alias link/definition (char/cellstr)
%         label: alias description (char/cellstr)
%         names: all defined alias names (cellstr)
% ex:     getalias(iData) or getalias(iData,'Signal')
%
% Version: $Revision: 1107 $
% See also iData, iData/set, iData/get, iData/setalias, iData/rmalias

% EF 23/09/07 iData implementation
% ============================================================================

if nargin == 1
  alias = '';
end

if numel(this) > 1
  link = cell(size(this)); label=link; names=link;
  parfor index=1:numel(this)
    [l,b,n] = getalias(this(index), alias);
    link{index} =l;
    label{index}=b;
    names{index}=n;
  end
  return
end

if isempty(alias)
  % NOTE: output arguments is shifted w.r.t. getalias(s,alias)
  link = this.Alias.Names(:);
  label= this.Alias.Values(:);
  names= this.Alias.Labels(:);
  return
end
names=alias;
alias_names = this.Alias.Names; % this is a cellstr of Alias names
alias_num   = find(strcmpi(alias, alias_names));

if isempty(alias_num)
  % this is not an alias. Try to get the content as char (link)
  try
    value= ~ischar(get(this, alias));
    this = struct(this);
    link = eval([ 'this.' alias ]);
    if value && ischar(link)
      return
    end
  end    
  link=[]; label=[]; 
else
  link = this.Alias.Values{alias_num};
  label= this.Alias.Labels{alias_num};
  if isempty(link) % default Error and Monitor definitions
    if     alias_num==2, link = 'sqrt(this.Signal)';
    elseif alias_num==3, link = 1; end
  end
end

