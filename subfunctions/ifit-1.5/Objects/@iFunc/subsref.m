function b = subsref(a,S)
% b = subsref(a,s) : iFunc indexed references
%
%   @iFunc/subsref: function returns subset indexed references
%     such as a(1:2) or a.field.
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/subsasgn

% This implementation is very general, except for a few lines

persistent fields

if isempty(fields), fields=fieldnames(iFunc); end

b = a;  % will be refined during the index level loop

if isempty(S)
  return
end

for i = 1:length(S)     % can handle multiple index levels
  s = S(i);
  switch s.type
  case '()' % ======================================================== array
    if numel(b) > 1           % iFunc array: b(index)
      b = b(s.subs{:});
    else                      % syntax iFunc(p, axes{:}, varargin) -> evaluate
      b = feval(b, s.subs{:});
    end
  case '.'  % ======================================================== structure
    % protect some fields     % iFunc Property
    fieldname = s.subs;
    if length(fieldname) > 1 && iscell(fieldname)
      fieldname = fieldname{1};
    end
    if isa(b, 'iFunc'), f=fields; else f=fieldnames(b); end
    index = find(strcmpi(fieldname, f));
    if ~isempty(index) % structure/class def fields: b.field
      b = b.(f{index});
      if isnumeric(b) && strcmpi(fieldname, 'Date')
        b = datestr(b);
      end
    elseif any(strcmp(fieldname, strtok(b.Parameters))) % b.<parameter name>
      index=find(strcmp(fieldname, strtok(b.Parameters)));
      if index <= length(b.ParameterValues) % last parameter value used
        b = b.ParameterValues;
        b = b(index);
      else
        b = [];
      end
    elseif strcmp(fieldname, 'p')               % b.p
      if ~isempty(b.ParameterValues)
        b = b.ParameterValues;
      else
        b = [];
      end
    elseif ismethod(b, fieldname)
      if i == length(S)
        if nargout(fieldname) ==0
          builtin('feval',fieldname, b);
          c=[];
        else
          c = builtin('feval',fieldname, b);
        end
      else
        c = builtin('feval',fieldname, b, S(i+1).subs{:}); i=i+1;
      end
      if isa(c, 'iFunc'), b = c; end
    else
      error([ mfilename ': can not get iFunc object Property ''' fieldname ''' in iFunc model ' b.Tag '.' ]);
    end
  end   % switch s.type
end % for s index level 
