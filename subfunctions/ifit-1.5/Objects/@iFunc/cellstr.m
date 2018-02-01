function [ret, header] = cellstr(s)
% ret = cellstr(s) : convert iFunc into a cell of strings
%
%   @iFunc/cellstr: function to convert iFunc objects into a cell of
%       strings e.g. for further evaluation. 
%   Returns the iFunc expression to evaluate
%
% input:  s: object or array (iFunc) 
% output: ret: iFunc identification (cellstr)
%
% Version: $Revision: 1163 $
% See also  iFunc/struct, iFunc/char
%


ret=[];
if numel(s) > 1
  ret = {};
  for index=1:numel(s)
    ret{index} = char(s(index));
  end
  return
end
  
% single object to char
  if isempty(s), ret={'[]'}; return; end

  ax = 'x,y,z,t,u,'; ax = ax(1:(s.Dimension*2));
  
  if isempty(s.Name) || strcmp(s.Name, char(s.Expression)), n  = s.Tag; else n=s.Name; end
  if strcmp(s.Expression, s.Description),             d = '';     else d = s.Description; end
  
  NL = sprintf('\n');
  % now we build up the header
  ret = { sprintf('%% signal=%s(p,%s ...) iFunc object %s', n, ax, s.Tag), '%' };
  if ~isempty(d) 
    d = textwrap(cellstr(d),80); 
    for index=1:length(d)
      ret{end+1} = sprintf('%% %s', d{index});
    end
    ret{end+1} = '%';
  end
  
  % in header: the Constraint+Expression
  ret{end+1} = '% Expression:';
  if ~isempty(s.Constraint)
    if isfield(s.Constraint, 'eval') && ~isempty(s.Constraint.eval)
      e = textwrap(cellstr(char(s.Constraint.eval)),80);
      if length(e) > 3, e=e(1:3); e{end+1} = '...'; end
      for index=1:length(e)
        ret{end+1} = sprintf('%%   %s', e{index});
      end
    end
  end
  e = textwrap(cellstr(char(s.Expression)),80);
  if length(e) > 3, e=e(1:3); e{end+1} = '...'; end
  for index=1:length(e)
    ret{end+1} = sprintf('%%   %s', e{index});
  end
  ret{end+1} = '%';
  ret{end+1} = '% input:';
  
  ret{end+1} = [ '%   p: Parameters (' num2str(length(s.Parameters)) ' values, degrees of freedom)' ];
  p = cellstr(s.Parameters);
  for index=1:length(p)
    line = sprintf('%%      p(%2d)=%s', index, p{index});

    if length(s.Constraint.min) >=index && isfinite(s.Constraint.min(index))
      this_min = s.Constraint.min(index);
    else
      this_min = -Inf;
    end
    if length(s.Constraint.max) >=index && isfinite(s.Constraint.max(index))
      this_max = s.Constraint.max(index);
    else
      this_max = Inf;
    end
    if length(s.Constraint.fixed) >=index && s.Constraint.fixed(index) ~= 0
      line = [ line ' (fixed)' ];
    elseif any(isfinite([this_min this_max]))
      line = [ line ' in ' mat2str([this_min this_max]) ];
    end
    ret{end+1} = line;

  end
  ret{end+1} = [ '%   ' ax(1:(end-1)) ': model axes (' num2str(s.Dimension) ' vector/matrix, dimensionality)' ];
  ret{end+1} = '%   ...: additional arguments to the model function';
  ret{end+1} = '% output:';
  ret{end+1} = '%   signal: function value or information';
  ret{end+1} = '';
  header = char(ret);

  % now write the core of the model (for evaluation)
  if ~isempty(s.Constraint)
    if isfield(s.Constraint, 'eval') 
      if isa(s.Constraint.eval ,'function_handle')
        ret{end+1} = sprintf('p2 = feval(%s, p, %s); p(~isnan(p2))=p2(~isnan(p2));', ...
          fun2str(s.Constraint), ax(1:(end-1)));
      elseif ~isempty(s.Constraint.eval)
        e = cellstr(s.Constraint.eval);
        for index=1:length(e)
          this = strtrim(e{index});
          if this(end) == ';'
            ret{end+1} = sprintf('%s\n', e{index});
          else
            ret{end+1} = sprintf('%s;\n', e{index});
          end
        end
      end
    end
    % these are handled in fits or feval, so we skip them
%    i = find(isfinite(s.Constraint.fixed));
%    if ~isempty(i)
%      ret{end+1} = sprintf('p(%s) = %s;', ...
%        mat2str(i), mat2str(s.Constraint.fixed(i)));
%    end
%    i = find(isfinite(s.Constraint.min));
%    if ~isempty(i)
%      ret{end+1} = sprintf('p(%s) = max(p(%s), %s);', ...
%        mat2str(i), mat2str(i),  mat2str(s.Constraint.min(i)));
%    end
%    i = find(isfinite(s.Constraint.max));
%    if ~isempty(i)
%      ret{end+1} = sprintf('p(%s) = min(p(%s), %s);', ...
%        mat2str(i), mat2str(i),  mat2str(s.Constraint.max(i)));
%    end
  end % constraint
  
  % the Expression has to return a 'signal' value in the last line
  if isa(s.Expression ,'function_handle')
    ret{end+1} = sprintf('signal = feval(%s, p, %s, varargin{:});', func2str(s.Expression), ax(1:(end-1)));
  else
    ret{end+1} = [ '% The Expression, computing signal from ''p'' and axes ' ax(1:(end-1)) ];
    e = s.Expression; 
    if ischar(e) % split char into lines
      e = textscan(e,'%s','Delimiter',sprintf('\n\r\f'),'MultipleDelimsAsOne',1); e=e{1};
    end
    has_signal = 0;
    for index=1:length(e)
      d = strtrim(e{index});
      if d(end) ~= ';', d = [ d '; ' ]; end
      if ~isempty(regexp(d, '\<signal\>\s*=')), has_signal = 1; end
      if index == length(e) && ~has_signal
        ret{end+1} = sprintf('signal = %s', d);
        has_signal = 1;
      else
        ret{end+1} = sprintf('%s', d);
      end
    end
  end

  % return value
  ret = reshape(ret,numel(ret),1); % as rows

  if nargout == 0 && ~isempty(inputname(1))
    s.Eval = ret;
    assignin('caller',inputname(1),s);
  end

