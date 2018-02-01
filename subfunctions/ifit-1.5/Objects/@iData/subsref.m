function b = subsref(a,S)
% b = subsref(a,s) : iData indexed references
%
%   @iData/subsref: function returns subset indexed references
%     such as a(1:2) or a.field.
%   The special syntax a{0} where a is a single iData returns the 
%     Signal/Monitor, and a{n} returns the axis of rank n.
%
% Version: $Revision: 1169 $
% See also iData, iData/subsasgn

% This implementation is very general, except for a few lines
% EF 27/07/00 creation
% EF 23/09/07 iData implementation
% ==============================================================================
% inline: private function iData_getAliasValue (mainly used)
% calls:  subsref (recursive), getaxis, getalias, get(Signal, Error, Monitor)

b = a;  % will be refined during the index level loop

persistent fields
persistent method

if isempty(fields), fields=fieldnames(iData); end
if isempty(method), method=methods('iData'); end

if isempty(S)
  return
end

for i = 1:length(S)     % can handle multiple index levels
  s = S(i);
  
  if ~isa(b, 'iData')
    b = subsref(b, s);
    continue;
  end
  switch s.type
  case '()' % ======================================================== array
    if numel(b) > 1   % iData array
      b = b(s.subs{:});
    else                  % single iData
      % this is where specific class structure is taken into account

      if ischar(s.subs{1}) && ~strcmp(s.subs{1},':')              % b(name) -> s.(name) alias/field value
        s.type='.';
        b=subsref(b, s); return;
      elseif isa(s.subs{1}, 'iFunc')                              % b(iFunc, par, ...)
        % evaluate model onto iData axes
        model      = s.subs{1};
        if length(s.subs) > 1
          pars = s.subs{2};
          s.subs(2) = [];
        elseif ~isempty(model.ParameterValues)
          pars = model.ParameterValues;
        else
          pars = '';
        end
        if isempty(pars), pars='guess'; end
        modelValue = feval(model, pars, b, s.subs{2:end});
        if strcmp(pars,'guess')
          modelValue = feval(model, modelValue, b, s.subs{2:end});
        end
        dm=iData_getAliasValue(b,'Monitor');
        if not(all(dm == 1 | dm == 0)) % fit(signal/monitor) 
          modelValue    = bsxfun(@times,modelValue, dm); 
        end
        setalias(b,'Signal', modelValue, model.Name);
        setalias(b,'Parameters', pars, [ model.Name ' model parameters for ' b.Title ]);
        b.Title = [ model.Name '(' char(b) ')' ];
        b.Label = b.Title;
        b.DisplayName = b.Title;
        setalias(b,'Error', 0);
        
        setalias(b,'Model', model, model.Name);
        return
      elseif any(cellfun('isempty',s.subs)), b=iData; return;        % b([])
      end
      if length(s.subs) == 1 && all(s.subs{:} == 1), continue; end  % b(1)
      
      iData_private_warning('enter',mfilename);
      
      b_isvector = isvector(b);
      ds=iData_getAliasValue(b,'Signal'); 
      d=ds(s.subs{:});                          % b(indices)
      b=set(b,'Signal', d);  b=setalias(b,'Signal', d);
      clear ds
      
      de=iData_getAliasValue(b,'Error'); 
      if numel(de) > 1 && isnumeric(de) 
        try % in case Error=sqrt(Signal), the Error is automatically changed when Signal is -> fail
          d=de(s.subs{:}); b=set(b,'Error', d); b = setalias(b, 'Error', d);
        end
      end
      clear de

      dm=iData_getAliasValue(b,'Monitor');
      if numel(dm) > 1 && isnumeric(dm)
        d=dm(s.subs{:}); b=set(b,'Monitor', d);  b = setalias(b, 'Monitor', d);
      end
      clear dm

      % must also affect axis
      % for event data sets, affect all axes
      if b_isvector, sz = b_isvector; else sz = ndims(b); end
      
      for index=1:sz
        if index <= length(b.Alias.Axis)
          x = getaxis(b,index);
          ax= b.Alias.Axis{index};   % definition of Axis
          nd = size(x); nd=nd(nd>1);
          if length(size(x)) == length(size(a)) && ...
                 all(size(x) == size(a))  && all(length(nd) == length(s.subs)) % meshgrid type axes
            b = setaxis(b, index, ax, x(s.subs{:}));
          elseif b_isvector && length(s.subs) == 1 % event data sets
            b = setaxis(b, index, ax, x(s.subs{1}));
          elseif max(s.subs{index}) <= numel(x) % vector type axes
            b = setaxis(b, index, ax, x(s.subs{index}));
          else
            iData_private_warning(mfilename,[ 'The Axis ' num2str(size(index)) ' [' ...
    num2str(size(x)) ' can not be resized as a [' num2str(size(s.subs{index})) ...
    '] vector in iData object ' b.Tag ' "' b.Title '".\n\tTo use the default Error=sqrt(Signal) assign s.Error=[].' ]);
          end
        end
      end 
      
      b = setaxis(copyobj(b));
      
      % add command to history
      if ~isempty(inputname(2))
        toadd =   inputname(2);
      elseif length(s.subs) == 1
        toadd =    mat2str(double(s.subs{1}));
      elseif length(s.subs) == 2
        toadd = [  mat2str(double(s.subs{1})) ', ' mat2str(double(s.subs{2})) ];
      else
        toadd =   '<not listable>';  
      end
      if ~isempty(inputname(1))
        toadd = [  b.Tag ' = ' inputname(1) '(' toadd ');' ];
      else
        toadd = [ b.Tag ' = ' a.Tag '(' toadd ');' ];
      end
  
      b = iData_private_history(b, toadd);
      % final check
      b = iData_check(b);
      % reset warnings
      iData_private_warning('exit',mfilename);

    end               % if single iData
  case '{}' % ======================================================== cell
    if isnumeric(s.subs{:}) 
      b=getaxis(b, s.subs{:});  % b{rank} value of axis
    elseif ischar(s.subs{:}) && ~isnan(str2double(s.subs{:}))
      b=getaxis(b, s.subs{:});  % b{'rank'} definition of axis
    elseif ischar(s.sub{:})
      b=getalias(b, s.subs{:}); % b{'alias'} same as b.'alias' definition
    else
      iData_private_error(mfilename, [ 'do not know how to extract cell index in ' inputname(1)  ' ' b.Tag '.' ]);
    end
  case '.'  % ======================================================== structure
    % protect some fields
    fieldname = s.subs;
    if length(fieldname) > 1 && iscell(fieldname)
      fieldname = fieldname{1};
    end
    
    f=fields; 
    % alias for a few iData fields
    if strcmpi(fieldname, 'filename') % 'alias of alias'
      fieldname = 'Source';
    elseif strcmpi(fieldname, 'history')
      fieldname = 'Command';
    elseif strcmpi(fieldname, 'axes')
      fieldname = 'Axis';
    end
    
    index = find(strcmpi(fieldname, f));
    if any(strcmpi(fieldname, 'alias'))
      b = getalias(b);
    elseif any(strcmpi(fieldname, 'axis'))
      b = getaxis(b);
    elseif ~isempty(index) % structure/class def fields: b.field
      b = b.(f{index(1)});
      if isnumeric(b) && any(strcmpi(fieldname, {'Date','ModificationDate'}))
        b = datestr(b);
      end
    elseif any(strcmpi(fieldname, a.Alias.Names))
      b = iData_getAliasValue(b,fieldname);
    elseif any(strcmp(fieldname,method)) % b.method = ismethod(b, fieldname)
      if i == length(S)
        if nargout(fieldname) ==0
          feval(fieldname, b);
          c = [];
        else
          c = feval(fieldname, b);
        end
      else
        c = feval(fieldname, b, S(i+1).subs{:}); i=i+1;
      end
      if isa(c, 'iData'), b = c; end
      if i == length(S), return; end
    else
      % check if the fieldname belongs directly to b.Data
      strtk = find(fieldname == '.', 1); strtk = fieldname(1:(strtk-1));
      if isempty(strtk), strtk = fieldname; end
      if isfield(b,'Data') && isstruct(b.Data) ...
              && all(~strcmpi(f, strtk)) && isfield(b.Data, strtk)
        fieldname = [ 'Data.' fieldname ];
      end
      if length(find(fieldname == '.')) >= 1
        b = get(b, fieldname);
      else
        b = iData_getAliasValue(b,fieldname); % get alias value from iData: b.<path> MAIN SPENT TIME
      end
    end
    
    % test if the result is again an Alias or Field
    if ischar(b) && size(b,1) == 1
      if any(strcmpi(b, fields))
        b = a.(b);      % fast access to static fields
      else
        % strtk = strtok(b,'.');
        strtk = find(b == '.', 1);        % first word
        if isempty(strtk), strtk = b;     % no '.' in the structure path
        else strtk = b(1:(strtk-1)); end  % get path before the last group
        % does the structure path starts with a registered iData property, alias or Data member ?
        if any(strcmpi(strtk, fields)) || any(strcmpi(strtk, a(1).Alias.Names)) ...
          || (isstruct(a.Data) && isfield(a.Data, strtk))
          b = get(a, b);  % try to evaluate char result/link
        end
      end
    end
  end   % switch s.type
end % for s index level

% ==============================================================================
% private function iData_getAliasValue
function val = iData_getAliasValue(this,fieldname)
% iData_getAliasValue: iData alias evaluation (not the link, but the value)
%   evaluates s.name to be first s.link, then 'link' (with 'this' defined).
%   NOTE: for standard Aliases (Error, Monitor), makes a dimension check on Signal

% EF 23/09/07 iData impementation
  val = [];
  if iscell(fieldname), fieldname = fieldname{1}; end
  if ~ischar(fieldname), return; end
  if ~isa(this, 'iData'),   return; end
  if ~isvarname(fieldname), return; end % not a single identifier (should never happen)

  % searches if this is an alias (it should be)
  alias_num   = find(strcmpi(fieldname, this.Alias.Names));  % index of the Alias requested
  if isempty(alias_num), 
    iData_private_error(mfilename, sprintf('can not find Property "%s" in object %s "%s".', fieldname, this.Tag, this.Title ));
    return; 
  end                    % not a valid alias
  
  alias_num = alias_num(1);
  name      = this.Alias.Names{alias_num};
  val       = this.Alias.Values{alias_num};  % definition/value of the Alias

  if (~isnumeric(val) && ~islogical(val))
    % the link evaluation must be numeric in the end...
    if ~ischar(val),       return; end  % returns numeric/struct/cell ... content as is.
    if  strcmp(val, name), return; end  % avoids endless iteration.
    
    % val is now only a char
    % handle URL content (possibly with # anchor)
    if  (strncmp(val, 'http://', length('http://'))  || ...
         strncmp(val, 'https://',length('https://')) || ...
         strncmp(val, 'ftp://',  length('ftp://'))   || ...
         strncmp(val, 'file://', length('file://')) )
      % evaluate external link
      val = iLoad(val); % stored as a structure
      return
    end
    
    % gets the alias value (evaluate the definition) this.alias -> this.val
    if ~isempty(val)
      % handle # anchor style alias
      if val(1) == '#', val = val(2:end); end % HTML style link
      % evaluate the alias definition (recursive call through get -> subsref)
      try
        % in case this is an other alias/link: this is were we propagate in the object
        val2 = '';
        while ischar(val) && ~strcmp(val2, val) % search until we resolve the Alias/link
          val = get(this,val); % gets this.(val)                    MAIN SPENT TIME
        end
      catch
        % evaluation failed, the value is the char (above 'get' will then issue a
        % 'can not find Property' error, which will come there in the end
      end
    end
  end

  % link value has been evaluated, do check in case of standard aliases
  if strcmp(fieldname, 'Error')         % Error is sqrt(Signal) if not defined 
    if ~isempty(val)
      if all(val(:) == val(end))
        val = val(end);
      end
    else
      s = iData_getAliasValue(this,'Signal');
      if isnumeric(s)
        val = sqrt(abs(double(s))); % main time spent on large arrays
      end
    end
    if ~isempty(val) && ~isscalar(val) && ~isequal(size(val),size(this))
      iData_private_warning(mfilename,[ 'The Error [' num2str(size(val)) ...
      '] has not the same size as the Signal [' num2str(size(this)) ...
      '] in iData object ' this.Tag ' "' this.Title '".\n\tTo use the default Error=sqrt(Signal) assign s.Error=[].' ]);
    end
  elseif strcmp(fieldname, 'Monitor')  % Monitor is 1 by default
    if isempty(val), val=1;
    elseif all(val(:) == val(end))
      val = val(end);
    end
    if val == 0, val=1; end
    if ~isempty(val) && length(val) ~= 1 && ~all(size(val) == size(this))
      iData_private_warning(mfilename,[ 'The Monitor [' num2str(size(val)) ...
        '] has not the same size as the Signal [' num2str(size(this)) ...
        '] in iData object ' this.Tag ' "' this.Title '".\n\tTo use the default Monitor=1 use s.Monitor=[].' ]);
    end
  end

