function disp(s_in, name)
% disp(s) : display iFunc object (details)
%
%   @iFunc/disp function to display iFunc model details
%
% input:  s: object or array (iFunc) 
% ex:     'disp(iFunc)'
%
% Version: $Revision: 1165 $
% See also iFunc, iFunc/display, iFunc/get

if nargin == 2 && ~isempty(name)
  iname = name;
elseif ~isempty(inputname(1))
  iname = inputname(1);
else
  iname = 'ans';
end

if numel(s_in) > 1
  eval([ iname ' = s_in;' ])
  eval([ 'display(' iname ');' ]); % makes sure the variable name is sent to 'display'.
else
  if isdeployed || ~usejava('jvm'), id='iFunc';
  else           id='<a href="matlab:doc iFunc">iFunc</a>';
  end
  fprintf(1,'%s = %s %iD model:\n',iname, id, s_in.Dimension);
  % clean up redundant/empty fields
  s = struct(s_in);
  if isfield(s.Constraint, 'eval') && ~isempty(s.Constraint.eval)
    u = char(s.Constraint.eval); u=strtrim(u); u(~isstrprop(u,'print'))=''; if ~isvector(u), u=u'; end
    if length(u) > 70, u = [ u(1:67) '...' ]; end
    if ~isempty(u)
      fprintf(1, '         Constraint: %s\n', u); 
    end
  end
  u=cellstr(s_in); u = u(~strncmp('%', u, 1)); % remove comment lines 
  u=[ u{:} ];
  u(~isstrprop(u,'print'))=''; if ~isvector(u), u=u'; end
  if length(u) > 70, u = [ u(1:67) '...' ]; end
  fprintf(1, '         Expression: %s\n', u); 
  u = u(1:min(length(u),60));
  if strcmp(s.Name, s.Description)       || isempty(s.Name),        s =rmfield(s, 'Name'); end
  if strcmp(u, s.Description) || isempty(s.Description), s =rmfield(s, 'Description'); 
  else
    u = s.Description; u=strtrim(u); u(~isstrprop(u,'print'))=''; if ~isvector(u), u=u'; end
    fprintf(1, '        Description: %s\n', s.Description); 
    s =rmfield(s, 'Description');
  end
  if isempty(s.Guess),                    s =rmfield(s, 'Guess'); end
  if isempty(s.Constraint),               s =rmfield(s, 'Constraint'); end
  s=rmfield(s, 'Eval');
  s=rmfield(s, 'Expression');
  if isnumeric(s.Date), s.Date=datestr(s.Date); end
  % object Properties displayed as a structure
  disp(s)
  % now display parameters in compact form
  if ~isempty(s.Parameters)
    fprintf(1,'Parameters (%i):\n', length(s.Parameters))
    for p=1:length(s.Parameters)
      [name, R] = strtok(s.Parameters{p}); % make sure we only get the first word (not following comments)
      R = strtrim(R);
      line = sprintf('  p(%3d)=%20s', p, name);
      val  = [];
      if ~isempty(s.ParameterValues)
        try
          val = s.ParameterValues(p);
        end
      end
      % add Constraint if meaningful
      if length(s.Constraint.min) >=p
        this_min = s.Constraint.min(p);
      else
        this_min = -Inf;
      end
      if length(s.Constraint.max) >=p
        this_max = s.Constraint.max(p);
      else
        this_max = Inf;
      end
      const = '';
      if length(s.Constraint.fixed) >=p && s.Constraint.fixed(p) ~= 0
        const = [ ' (fixed)' ];
      elseif any(isfinite([this_min this_max]))
        const = [ ' in ' mat2str([this_min this_max]) ];
      end
      if length(s.Constraint.set) >=p && ~isempty(s.Constraint.set{p}) && ...
        (ischar(s.Constraint.set{p}) || isa(s.Constraint.set{p}, 'function_handle'))
        const = [ const ' set from ' char(s.Constraint.set(p)) ];
      end
      if ~isempty(val) && isfinite(val), line = [ line sprintf('=%g ', val)  ]; end
      if ~isempty(const), line = [ line const ]; end
      if ~isempty(R),     line = [ line sprintf('  %% entered as: %s', R) ]; end
      fprintf(1, '%s\n', line);
    end

  end
  
end


