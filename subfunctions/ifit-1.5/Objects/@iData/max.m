function [m,id] = max(a,b, dim)
% [m,id] = max(a,b, dim) : computes the maximum value of iData object(s)
%
%   @iData/max function to compute the maximum value of data sets.
%     max(iData) returns a single value as the maximum value of the iData signal
%     max(a,b)   returns an object which signal is the highest of a and b.
%     max(a,[], dim) returns max value along dimension 'dim'
%
% input:  a: object or array (iData)
%         b: object or array (iData/double)
%         dim: dimension on which to operate
%
% output: m:  maximum value (double/iData)
%         id: returns the indices of the maximum value (integer)
% ex:     b=max(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/max, iData/min

if nargin == 1
  b = [];
end
if nargin <= 2
  dim = [];
end
id=[];

% handle input iData arrays
if numel(a) > 1 & isa(a,'iData')
  m = [];
  for index=1:numel(a)
    [y,i] = max(a(index), b, dim);
    m  = [ m  y ];
    id = [ id i ]; 
  end
  m = reshape(m, size(a));
  return
end

if ~isa(a, 'iData')
  [m,id] = max(b, a, dim);
  return
end

% return a scalar for max(a)
if isempty(b) && isempty(dim)
  m = get(a, 'Signal');
  [m,id] = max(m(:));
  return
end

% find intersection between iData objects
cmd=a.Command;
if isa(b, 'iData')
  [a,b] = intersect(a,b);
  m = copyobj(a);
  set(m, 'Signal', max(get(a,'Signal'), get(b,'Signal')));
  return
else
% handle iData and scalar/vector/matrix min/max
  m = copyobj(a);
  if isempty(dim) || ~isempty(b)
    [y,id] = max(get(a,'Signal'), b);
    set(m, 'Signal', y);
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
    [y,id] = max(get(a,'Signal'), [], dim);
    set(m, 'Signal', y, [mfilename ' of ' label(a) ]);     % Store Signal
  end
end
m.Command=cmd;
m = iData_private_history(m, mfilename, a, b);


