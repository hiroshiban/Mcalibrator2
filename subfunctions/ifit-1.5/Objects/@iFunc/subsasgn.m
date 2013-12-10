function b = subsasgn(a,S,val)
% b = subsasgn(a,index,b) : iFunc indexed assignement
%
%   @iFunc/subsasgn: function defines indexed assignement
%   such as a(1:2,3) = b
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/subsref

% This implementation is very general, except for a few lines

persistent fields

if isempty(fields), fields=fieldnames(iFunc); end

b = a;  % will be refined during the index level loop

if isempty(S)
  return
end

% first handle object array for first index
if numel(b) > 1 && any(strcmp(S(1).type,{'()','{}'}))
  c = b(S(1).subs{:}); % get elements in the array
  if ~isvector(c) d = c(:); else d=c; end
  if length(d) == 1
    d = iFunc(val);
  else
    if ~isempty( S(2:end) ) % array([1 2 3]).something = something
          for j = 1:length(d)
            d(j) = subsasgn(d(j),S(2:end),val);
          end
        else    % single level array assigment as array([1 2 3]) = something
            for j = 1:length(d)
                if length(val) == 1, d(j) = iFunc(val);
                elseif length(val) == length(d)
                    d = iFunc(val);
                else
                    error([ mfilename ': can not assign ' num2str(length(d)) ' iFunc array to ' num2str(length(val)) ' ' class(val) ' array for object ' inputname(1) ' ' b(1).Tag ]);
                end
            end
        end
  end
  if prod(size(c)) ~= 0 && prod(size(c)) == prod(size(d)) && length(c) > 1
    c = reshape(d, size(c));
  else
    c = d;
  end
  b(S(1).subs{:}) = c;
else
  % multiple level assignment: only the last subs indexing must be assigned, the previous ones must be subsref calls
  if length(S) > 1
    for i=1:(length(S)-1)
      b = subsref(b, S(i));       % navigate to the pre-last level -> b, e.g. not an iFunc
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
      c = [];
      for j = 1:length(s.subs{:})
        c = [ c subsasgn(c(j),s,val) ];
      end
      b = reshape(c, size(b));
    end                 % if single object
  case '.'
  % SYNTAX: object.field = val
    if numel(b) > 1   % object array -> deal on all elements
      c = [];
      for j = 1:length(c)
        c = [ c subsasgn(c(j),s,val) ];
      end
      b = reshape(c, size(b));
    else
    % protect some fields
      fieldname = s.subs;
      if length(fieldname) > 1 && iscellstr(fieldname)
        fieldname = fieldname{1};
      end
      if isa(b, 'iFunc'), f=fields; else f=fieldnames(b); end
      index = find(strcmpi(fieldname, f));
      if ~isempty(index) % structure/class def fields: b.field
        if strcmp(f{index},'Constraint') && ~isstruct(val)
          if ischar(val) || iscellstr(val) || isa(val,'function_handle')
            b.Constraint.eval = val;
          elseif isnumeric(val) && isscalar(val)
            b.Constraint.fixed = val*ones(length(b.Parameters),1);
          elseif isnumeric(val) && length(val) == length(b.Parameters)
            b.Constraint.fixed = val(:);
          else
            error(['iFunc:' mfilename ], [mfilename ': the model Constraint should be a char or cellstr, function_handle, struct, scalar or Parameter-length vector, but not a ' ...
        class(val) '.' ]);
          end
        else
          b.(f{index}) = val;
        end
        if any(strcmp(f{index},{'Expression','Constraint'}))
          % must triger new Eval string
          b.Eval='';
          % check object when modifying key member
          b = iFunc(b);
        end
      elseif any(strcmp(fieldname, strtok(b.Parameters))) % b.<parameter name> = <value>
        index=find(strcmp(fieldname, strtok(b.Parameters)));
        if isnumeric(val) && isscalar(val)  % set constraint: scalar
          if index > length(b.ParameterValues)
b.ParameterValues((length(b.ParameterValues)+1):(index-1)) = NaN;
          end
          b.ParameterValues(index)  = val;
        else                                % set constraint: 'fix', 'clear', 'set', [min max]
          if ischar(val) && any(strncmp(val, {'fix','loc'}, 3))
            b.Constraint.fixed(index) = 1; val = 'skip';
          elseif ischar(val) && any(strncmp(val, {'cle','unl'}, 3))
            b.Constraint.fixed(index) = 0; val = 'skip';
          elseif ischar(val) && any(length(str2num(val)) == [1 2])
            val = str2num(val);
          end
          if isempty(val)
            b.Constraint.fixed(index) = 0;
            b.Constraint.min(index)   = nan;
            b.Constraint.max(index)   = nan;
            b.Constraint.set{index}   = [];
          elseif (~strcmp(val, 'skip') && ischar(val)) || isa(val, 'function_handle')
            % replace occurencies of Parameter names (as single words)
            if ischar(val)
              % build the list of replacement strings
              replace = strcat('p(', cellstr(num2str(transpose(1:length(b.Parameters)))), ')');
              % replace Parameter names by their p(n) representation
              val = regexprep(val, strcat('\<"', strtok(b.Parameters), '"\>' ), replace);
            end
            b.Constraint.set{index}   = val;
            b.Constraint.fixed(index) = 1; % this also fixes the value
          elseif isnumeric(val) && length(val)==2
            % val=[min max] -> set min(index) and max(index)
            b.Constraint.min(index) = val(1);
            b.Constraint.max(index) = val(2);
          elseif isnumeric(val) && length(val)==1 % from str2num(char) above
            % val='value' -> set value and fix it
            b.ParameterValues(index)  = val;
            b.Constraint.fixed(index) = 1;
          end
        end
        % check object when modifying key member
        b = iFunc(b);
      elseif strcmp(fieldname, 'p')
        if isnumeric(val)
          b.ParameterValues=val;
          b.Constraint.fixed(index) = nan;
        end
      else
        error([ mfilename ': can not set iFunc object Property ''' fieldname ''' in iFunc model ' b.Tag '.' ]);
      end
    end
  end   % switch s.type

end 
