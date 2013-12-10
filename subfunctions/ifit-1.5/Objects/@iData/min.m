function m = min(a,b, dim)
% m = min(a,b,dim) : computes the minimum value of iData object(s)
%
%   @iData/min function to compute the minimum value of data sets.
%     min(iData) returns a single value as the minimum value of the iData signal
%     min(a,b)   returns an object which signal is the lowest of a and b.
%     min (a,[], dim) returns max value along dimension 'dim'
%
% input:  a: object or array (iData)
%         b: object or array (iData/double)
%         dim: dimension on which to operate
%
% output: m: minimum value (double/iData)
% ex:     b=min(a); or min(a,1)
%
% Version: $Revision: 1035 $
% See also iData, iData/min, iData/max

if nargin == 1
  b = [];
end
if nargin <= 2
  dim = [];
end

% handle input iData arrays
if numel(a) > 1 & isa(a,'iData')
  m = [];
  for index=1:numel(a)
    m = [ m min(a(index), b, dim) ];
  end
  m = reshape(m, size(a));
  return
end

if ~isa(a, 'iData')
  m = min(b, a, dim);
  return
end

% return a scalar for min(a)
if isempty(b) && isempty(dim)
  m = get(a, 'Signal');
  m = min(m(:));
  return
end

% find intersection between iData objects
cmd=a.Command;
if isa(b, 'iData')
  [a,b] = intersect(a,b);
  m = copyobj(a);
  set(m, 'Signal', min(get(a,'Signal'), get(b,'Signal')));
  return
else
% handle iData and scalar/vector/matrix min/min
  m = copyobj(a);
  if isempty(dim) || ~isempty(b)
    set(m, 'Signal', min(get(a,'Signal'), b));
  else
    rmaxis(m); % delete all axes
    % copy all axes except the one on which operation runs
    ax_index=1;
    for index=1:ndims(a)
      if index ~= dim
        setaxis(m, ax_index, getaxis(a, num2str(index)));
        ax_index = ax_index+1;
      end
    end
    set(m, 'Signal', min(get(a,'Signal'), [], dim), [mfilename ' of ' label(a) ]);     % Store Signal
  end
end
m.Command=cmd;
m = iData_private_history(m, mfilename, a, b);


