function a = xlim(a, varargin)
% b = xlim(s, parameters, [min max], ...) : sets parameter bounds (min,max) for further fit using the model 's'
%
%   @iFunc/xlim bound model parameters during further fit process.
%
%   To bound a set of parameters, you may use a regular expression as:
%     xlim(model, regexp(model.Parameters, 'token1|token2|...'), [min max])
%
%   xlim(model, parameter, [min max])
%     limit a parameter in model within [min max]. Inf and NaNs are ignored.
%   xlim(model, parameter, [])
%     remove the parameter bounds in model
%   xlim(model, parameter)
%     return the current parameter limits
%   xlim(model)
%     display bounded parameters
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=xlim(a,'Intensity',[0 1]);
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/unlock, iFunc/lock

% calls subsasgn with [min max] for each parameter given

% handle array of objects
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index), varargin{:});
  end
  return
end

if nargin == 1 % display bounded parameters
  count = 0;
  if ~isempty(a.Parameters)
    for p=1:length(a.Parameters)
      [name, R] = strtok(a.Parameters{p}); % make sure we only get the first word (not following comments)
      if length(a.Constraint.min) >=p
        this_min = a.Constraint.min(p);
      else
        this_min = -Inf;
      end
      if length(a.Constraint.max) >=p
        this_max = a.Constraint.max(p);
      else
        this_max = Inf;
      end
      
      if any(isfinite([this_min this_max]))
        if (count == 0)
          fprintf(1, 'Bounded Parameters in %s %iD model "%s"\n', a.Tag, a.Dimension, a.Name)
        end
        count = count +1;
        fprintf(1,'%20s in %s\n', name,  mat2str([this_min this_max]));
      end
    end
  end
  if count == 0
    fprintf(1, 'No Bounded Parameters in %s %iD model "%s"\n', a.Tag, a.Dimension, a.Name);
  end
  return
end

% handle case where names are obtained from regexp = cell with length=Parameters
if length(varargin) >= 1 && length(varargin{1}) == length(a.Parameters)
  varargin{1} = a.Parameters(find(~cellfun(@isempty, varargin{1})));
end

% handle multiple parameter name arguments
value = [];
if length(varargin) > 2
  for index=1:2:length(varargin)
    % search for char|cellstr, numeric, by pairs
    if (ischar(varargin{index}) || iscellstr(varargin{index}))
      name  = varargin{index};
      if index < length(varargin) && (isnumeric(varargin{index+1}) || isempty(varargin{index+1}) )
        value = varargin{index+1};
      else
        value = [];
      end
      a = feval(mfilename, a, name, value);
    end
  end
  return
else
  name = varargin{1};
  if length(varargin) >= 2, value = varargin{2}; end
end

if ~ischar(name) && ~iscellstr(name)
  error([ mfilename ': can not lock model parameters with a Parameter name of class ' class(name) ' in iFunc model ' a.Tag '.' ]);
end

% now with a name/value

if ischar(name), name = cellstr(name); end

% now with a single cellstr
if nargin == 2
  b = [];
else
  b = a;
end
for index=1:length(name)
  i=find(strcmp(name{index}, a.Parameters));
  if ~isempty(i)
    if nargin == 2 % xlim(a,'Paramater') -> [ min max ]
      % return current bounds
      b = [ b ; a.Constraint.min(index) a.Constraint.max(index) ];
    else
      s    = struct('type', '.', 'subs', name{index});
      b    = subsasgn(b, s, value);
    end
  else
    warning([ mfilename ': unknown parameter ' name{index} ' in iFunc model ' a.Tag '.' ]);
  end
end
a = b;

if nargout == 0 && ~isempty(inputname(1)) && ~isnumeric(a)
  assignin('caller',inputname(1),a);
end

