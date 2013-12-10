function b = subsasgn(a,S,val)
% b = subsasgn(a,index,b) : iData indexed assignement
%
%   @iData/subsasgn: function defines indexed assignement 
%   such as a(1:2,3) = b
%   The special syntax a{0} multiplies the value by the Monitor and then assigns 
%   the Signal, and a{n} assigns the axis of rank n.
%     When the assigned value is a char, the axis definition is set (as in setaxis).
%     When the assigned value is numeric, the axis value is set (as in set).
%   The special syntax a{'alias'} is a quick way to define an alias.
%
% Version: $Revision: 1158 $
% See also iData, iData/subsref

% This implementation is very general, except for a few lines
% EF 27/07/00 creation
% EF 23/09/07 iData implementation

b = a;  % will be refined during the index level loop

persistent fields

if isempty(fields), fields=fieldnames(iData); end

if isempty(S)
  return
end

% first handle object array for first index
if numel(b) > 1 && any(strcmp(S(1).type,{'()','{}'}))
  c = b(S(1).subs{:}); % get elements in the array, to be assigned
  sc=size(c); % store size so that we restore it at the end

  if numel(c) == 1
    c = iData(val);
  else
    if ~isempty( S(2:end) ) % array([1 2 3]).something = something
      for j = 1:numel(c)
        c(j) = subsasgn(c(j),S(2:end),val);
      end
    elseif isa(val, 'iData') && numel(val) == numel(c)
      c = iData(val); % array([1 2 ..]) = iData_array([1 2 ..])	
    else    % single level array assigment as array([1 2 3]) = something
      for j = 1:numel(c)
        try
          c(j) = iData(val);
        catch
          iData_private_error(mfilename, [ 'can not assign ' num2str(length(c)) ' iData array to ' num2str(length(val)) ' ' class(val) ' array for object ' inputname(1) ' ' b(1).Tag ]);
        end
      end
    end
  end

  if prod(sc) ~= 0 && prod(sc) == prod(size(c)) && numel(c) > 1
    c = reshape(c, size(c));
  end
  b(S(1).subs{:}) = c; % update the array
else
  % multiple level assignment: only the last subs indexing must be assigned, the previous ones must be subsref calls
  if length(S) > 1
    for i=1:(length(S)-1)
      b = subsref(b, S(i));       % navigate to the pre-last level -> b, e.g. not an iData
    end
    b = subsasgn(b, S(end), val); % assigment for last level
    b = subsasgn(a, S(1:(end-1)), b);
    return
  end
  
  % single level assignment
  s = S(1);
  switch s.type
  case '()'
    if numel(b) > 1   % array() -> deal on all elements
    % SYNTAX: array(index) = val: set Data using indexes         
      parfor j = 1:length(s.subs{:})
        b(j) = subsasgn(b(j), s,val);
      end
    elseif ~isa(val, 'iData') % single object() = Signal (val must be num)
    % SYNTAX: object(index) = numeric: set Signal, index can be a subset
      if ~isnumeric(val)
        st = num2str(s.subs{1}); 
        if length(st) > 10,    st=[ st(1:10) '...' ]; end
        if length(s.subs) > 1, st = [ st ', ...' ]; end
        iData_private_error(mfilename, [ 'object(' st ') = ' class(val) ' but expects a numerical value or iData object to assign Signal in object ' inputname(1) ' ' b.Tag ]);
      end
      % this is where specific class structure is taken into account
      cmd=b.Command;
      d = get(b, 'Signal');
      d(s.subs{:}) = val;
      b = iData_setalias(b, 'Signal', d);
      if isempty(val) % remove columns/rows in data: Update Error, Monitor and Axes
        for index=1:ndims(b)
          x = getaxis(b,index);
          if all(size(x) == size(b)) % meshgrid type axes
            x(s.subs{:}) = [];
          else  % vector type axes
            x(s.subs{index}) = [];
          end
          b = setaxis(b, index, x);
        end
      end
      
      % add command to history
      toadd = '(';              % indices
      if ~isempty(inputname(2))
        toadd = [ toadd inputname(2) ];
      else
        toadd = [ toadd iData_mat2str(s.subs{:}) ];
      end
      toadd = [ toadd ') = ' ]; % values
      if ~isempty(inputname(3))
        toadd = [ toadd inputname(3) ];
      else
        toadd = [ toadd iData_mat2str(val) ];
      end
      if ~isempty(inputname(1))
        toadd = [ inputname(1) toadd ';' ];
      else
        toadd = [ a.Tag toadd ';' ];
      end
      b.Command=cmd;
      b = iData_private_history(b, toadd);
      % final check
      b = iData(b);
    elseif length(s.subs) == 1 && length(s.subs{:}) == 1 && s.subs{:} == 1
    % SYNTAX: object(1) = iData: just assign objects on common axis frame
      [b,val]=union(b,val); % extrapolated values from 'val' are set to zero by interp
      val = subsref(val,struct('type','.','subs','Signal'));  % values to use for assignment
      i   = find(val);
      sb  = subsref(b,struct('type','.','subs','Signal'));    % signal to assign
      sb(i) = val(i);
      b   = iData_setalias(b, 'Signal', sb);
      return
    elseif length(s.subs) == ndims(val)
      % a(index) = iData(index)
      sb  = subsref(b,struct('type','.','subs','Signal'));    % signal to assign
      sb  = subsref(sb, s);
      if all(size(sb) == size(val))
        b = subsasgn(a, s, double(val));
      end
    else 
      iData_private_warning(mfilename, [ 'I can only allocate a sub-object with syntax ' b.Tag ' ' inputname(1) '(1) = ' val.Tag ' which asssigns unweighted Signal. Ignoring and leaving target object unchanged.' ]);
    end                 % if single object
  case '{}'
    if numel(b) > 1   % object array -> deal on all elements
    % SYNTAX: array{ref}=val
      parfor j = 1:numel(b)
        b(j) = subsasgn(b(j),s,val);
      end
    else
    % object{ref}
      if isnumeric(s.subs{:}) && isscalar(s.subs{:}) && ischar(val)
      % SYNTAX: object{axis_rank} = 'val' -> set the alias
        setaxis(b, s.subs{:}, val);
      elseif isnumeric(s.subs{:}) && isscalar(s.subs{:}) && isnumeric(val)
      % SYNTAX: object{axis_rank} = val -> set the value
        setaxis(b, s.subs{:}, '', val);
      elseif ischar(s.subs{:}) && ~isempty(str2num(s.subs{:}))
      % SYNTAX: object{'axis_rank'} = val -> object{axis_rank} = val
        b=setaxis(b, str2num(s.subs{:}), val);
      elseif ischar(s.subs{:})
      % SYNTAX: object{'field'} = val
        b=setalias(b, s.subs{:}, val);
      else
      % SYNTAX: object{index} = other: will probably fail...
        b{s.subs{:}} = val;       
      end
    end
  case '.'
  % SYNTAX: object.field = val
    if numel(b) > 1   % object array -> deal on all elements
      parfor j = 1:length(b)
        b(j) = subsasgn(b(j),s,val);
      end
    else
    % protect some fields
      fieldname = s.subs;
      if length(fieldname) > 1 && iscell(fieldname) && ischar(fieldname)
        fieldname = fieldname{1};
      end
      if strcmpi(fieldname, 'filename') % 'alias of alias'
        fieldname = 'Source';
      elseif strcmpi(fieldname, 'history')
        fieldname = 'Command';
      elseif strcmpi(fieldname, 'axes')
        fieldname = 'Axis';
      elseif strcmpi(fieldname, 'title')
        T   = val; if ~ischar(T), T=char(T); end
        if size(T,1)~=1, T=transpose(T); T=T(:)'; end
        T   = regexprep(T,'\s+',' '); % remove duplicated spaces
        val = T;
      end
      if any(strcmpi(fieldname, {'alias','axis'}))
        iData_private_warning(mfilename, [ 'redefine ' fieldname ' in object ' inputname(1) ' ' b.Tag ]);
      end
      if isa(b, 'iData'), f=fields; else f=fieldnames(b); end
      index = find(strcmpi(fieldname, f));
      if ~isempty(index) % structure/class def fields: b.field
        b.(f{index}) = val;
      else
        strtk = find(fieldname == '.', 1); strtk = fieldname(1:(strtk-1));
        if isempty(strtk), strtk = fieldname; end
        if (isstruct(b) || isa(b,'iData')) && isstruct(b.Data) && isfield(b.Data, strtk)
          b.Data.(fieldname) = val;
        else
          if strcmpi(fieldname, 'Signal') && isempty(val)
            b = setalias(b, 'Signal', []);        % reset Signal to the biggest field
          elseif ischar(val) && strcmp(strtk, fieldname)
            lab = label(b, val);
            if isempty(lab), lab = val; end
            b = setalias(b, fieldname, val, lab);
          else
            b = iData_setalias(b,fieldname, val); % set alias value from iData: b.alias
          end
        end
      end
    end
  end   % switch s.type
  
end

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),b);
end

% ==============================================================================
% private function iData_setalias
function this = iData_setalias(this, alias, val)
% iData_setalias: iData alias assigment
%   assigns s.alias=val
%   NOTE: for standard Aliases (Error, Monitor), makes a dimension check on Signal

  if ~isa(this, 'iData'),   return; end
  if ~isvarname(alias), return; end % not a single identifier (should never happen)

  % searches if this is an alias (it should be)
  alias_num   = find(strcmpi(alias, this.Alias.Names));  % index of the Alias requested
  if isempty(alias_num), 
    iData_private_warning(mfilename, sprintf('Can not find Property "%s" in object %s. Creating it.', alias, this.Tag ));
    setalias(this, alias, val);
    return
  end                    % not a valid alias
  
  alias_num = alias_num(1);
  name      = this.Alias.Names{alias_num};
  link      = this.Alias.Values{alias_num};  % definition/value of the Alias
  
  % handle URL content (possibly with # anchor)
  if ischar(link)
  if  (strncmp(link, 'http://', length('http://'))  || ...
       strncmp(link, 'https://',length('https://')) || ...
       strncmp(link, 'ftp://',  length('ftp://'))   || ...
       strncmp(link, 'file://', length('file://')) )
    % can not assign external link
    iData_private_warning(mfilename, sprintf('can not assign external Property "%s"="%s" in object %s. Ignoring.', ...
      fieldname, link, this.Tag ));
    return
  end
  end
  
  updated = 0;
  if ischar(link) && ~isempty(link)
    % if the alias definition is char, then we update the link
    if link(1) == '#', link = link(2:end); end % HTML style link anchor
    try
      set(this, link, val);
      updated = 1;
    catch
    end
  end
  if ~updated
    % if the alias definition is numeric/structure/..., then this is the value and we directly store it
    this.Alias.Values{alias_num} = val;
  end
  
% ==============================================================================
function toadd=iData_mat2str(varargin)

toadd ='';
for index=1:length(varargin)
  if index==1, c=''; else c=','; end
  b = varargin{index};
  if ischar(b)
    if numel(b) > 100, b=[ b(1:20) '...' b((end-20):end) ]; end 
    toadd = [ toadd c ' ''' b '''' ];
  elseif isa(b, 'iData')
    toadd = [ toadd ' <' class(b) ' ' b.Tag ' ' b.Source '> ' ];
  elseif isnumeric(b) || islogical(b) 
    if ndims(b) > 2,   b=b(:); end
    if numel(b) > 50, toadd = [ toadd c ' [' mat2str(double(b(1:20))) '...' mat2str(double(b((end-20):end))) ']' ]; 
    else 
      toadd = [ toadd c ' ' mat2str(double(b)) ];
    end
  else
    toadd = [ toadd c ' <' class(b) '>'  ];
  end
end
