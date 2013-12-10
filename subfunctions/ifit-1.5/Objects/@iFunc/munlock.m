function a = munlock(a, varargin)
% b = munlock(s, parameters, ...) : free parameter lock (clear) for further fit using the model 's'
%
%   @iFunc/munlock unlock model parameters during further fit process.
%     to unlock/clear a parameter model, use munlock(model, parameter)
%
%   To unlock/free a set of parameters, you may use a regular expression as:
%     munlock(model, regexp(model.Parameters, 'token1|token2|...'))
%
%   munlock(model, {'Parameter1', 'Parameter2', ...})
%     unlock/free parameter for further fits
%   munlock(model)
%     display free parameters
%
% input:  s: object or array (iFunc)
% output: b: object or array (iFunc)
% ex:     b=munlock(a,'Intensity');
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/fits, iFunc/mlock, iFunc/xlim

% calls subsasgn with 'clear' for each parameter given

% handle array of objects
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index), varargin{:});
  end
  if nargout == 0 && ~isempty(inputname(1)) % update array inplace
    assignin('caller', inputname(1), a);
  end
  return
end

if nargin == 1 % display free parameters
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
      
      if length(a.Constraint.fixed) >=p && ~a.Constraint.fixed(p)
        if (count == 0)
          fprintf(1, 'Unlocked/Free Parameters in %s %iD model "%s"\n', a.Tag, a.Dimension, a.Name)
        end
        count = count +1;
        if any(isfinite([this_min this_max]))
          fprintf(1,'%20s (free) in %s\n', name, mat2str([this_min this_max]));
        else
          fprintf(1,'%20s (free)\n', name);
        end
      end
    end
  end
  if count == 0
    fprintf(1, 'No unlocked/free Parameters in %s %iD model "%s"\n', a.Tag, a.Dimension, a.Name);
  end
  a = count;
  return
end

% handle case where names are obtained from regexp = cell with length=Parameters
if length(varargin) == 1 && length(varargin{1}) == length(a.Parameters)
  varargin{1} = a.Parameters(find(~cellfun(@isempty, varargin{1})));
end

% handle multiple parameter name arguments
if length(varargin) > 1
  for index=1:length(varargin)
    a = feval(mfilename, a, varargin{index});
  end
  return
else
  name = varargin{1};
end

% now with a single input argument
if ~ischar(name) && ~iscellstr(name)
  error([ mfilename ': can not unlock model parameters with a Parameter name of class ' class(name) ' in iFunc model ' a.Tag '.' ]);
end

if ischar(name), name = cellstr(name); end
% now with a single cellstr
for index=1:length(name)
  s    = struct('type', '.', 'subs', name{index});
  a = subsasgn(a, s, 'clear');
end

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),a);
end

