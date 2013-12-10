function b = cat(varargin)
% s = cat(dim,a,...) : catenate iData objects elements along dimension
%
%   @iData/cat function to catenate iData objects elements along dimension dim
%     cat(dim,a,b,c,...) catenates along axis of rank dim. The axis is then extended.
%     cat(1,a,...) accumulates on first dimension (columns)
%     cat(a,b...)  accumulates on first dimension (columns) (uses dim=1)
%     cat(0,a,...) catenates objects along a new dimension (dim = ndims(a)+1)
%
% input:  a: object or array (iData/array of)
%         dim: dimension to accumulate (int)
% output: s: catenated data set (iData)
% ex:     c=cat(1,a,b); c=cat(1,[ a b ]); 
%
% Version: $Revision: 1158 $
% See also iData, iData/plus, iData/prod, iData/cumcat, iData/mean

% first parse inputs searching for the dimension, and building the object array
dim=1; a=[];
for index=1:length(varargin)
  this=varargin{index};
  if ~isa(this,'iData') && isnumeric(this)
    dim = this;
  elseif isa(this,'iData')
    if numel(this) > 1
      this = reshape(this, 1, numel(this));
    end
    a = [ a this ];
  end
end

if all(isempty(a))
  iData_private_error(mfilename,['syntax is cat(dim, iData, ...)']);
end

if isempty(dim) || dim <= 0 || dim > ndims(a(1))
  dim = ndims(a(1))+1;
end

% syntax is now: cat(dim,[a(:)])
if numel(a) <= 1, b=a; return; end
if dim <= 0, dim=1; end

% removes warnings during interp
iData_private_warning('enter', mfilename);

% syntax is now: cat(dim,[a b c ... ])
if ~any(isvector(a)>1)
  % first need to compute union axes, but not for dimension 'dim'
  c_axis = iData_private_caxis(a,'union');
  % use common axes on all axes except dim
  for index=1:numel(a)
    x = getaxis(a(index), dim);
    if length(x) == 1 || length(x) == length(a)
      c_axis{dim} = x; % restore initial 'dim' axis from object. Others are the common axes.
    end
    if dim > ndims(a(index))
      a(index) = interp(a(index), c_axis);
    end
  end
else
  if dim ~= 1
    iData_private_warning(mfilename, [' Event data sets can only be catenated one after the other. Using dim=1.']);
  end
  dim = 1; % can only catenate one after the other event sets
end

% now catenate Signal, Error and Monitor 
lab = label(a, 0); 

if iscell(lab) && ischar(lab{1}), lab=[ lab{1} '...' ]; end
s=cell(1,numel(a));
parfor index=1:numel(a)
  s{index}=get(a(index),'Signal');
  if isvector(s{index}), ss=s{index}; ss=ss(:); s{index}=ss; end
end
ss = cat(dim, s{:});

% now build final result
cmd = get(a(1),'Command');
b = copyobj(a(1));  % with extended (union) axes
setalias(b,'Signal', ss, [ 'catenated ' lab ]);     % Store Signal
clear ss

% Error handling
% first test if all Errors are sqrt(this.Signal) (that is default=[])
% first test if all Monitors are 1 (that is default=[])
se = 1; sm = 1;
for index=1:numel(a)
  if ~strcmp(getalias(a(index),'Error'), 'sqrt(this.Signal)')
    se = 0;
  end
  if ~isnumeric(getalias(a(index), 'Monitor')) || length(getalias(a(index), 'Monitor')) > 1
    sm = 0;
  end
end

% then decide what to catenate for Error
if se == 1  % all Errors are default, just copy the default
  se = [];
else
  % some Errors are not default: we catenate all of them as values
  for index=1:length(a)
    se = getalias(a(index),'Error');
    if ~isnumeric(se) || ~isscalar(se)
      se = get(a(index),'Error');
    end
    s{index} = ones(size(get(a(index),'Signal'))).*se;
    if isvector(s{index}), se=s{index}; se=se(:); s{index}=se; end
  end
  se = cat(dim, s{:});
end
setalias(b,'Error',  se);
clear se

% then decide what to catenate for Monitors
if sm == 1  % all Monitors are default, just copy the default
  sm = [];
else
  % some Monitors are not default: we catenate all of them as values
  parfor index=1:numel(a)
    sm = getalias(a(index),'Monitor');
    if ~isnumeric(sm) || ~isscalar(sm)
      sm = get(a(index),'Monitor');
    end
    s{index} = ones(size(get(a(index),'Signal'))).*sm;
    if isvector(s{index}), sm=s{index}; sm=sm(:); s{index}=sm; end
  end
  sm = cat(dim, s{:});
end
setalias(b,'Monitor',sm);
clear sm

% event data set: catenate all axes
% histogram data set: catenate only dimension 'dim'
for d=1:ndims(a(1))
  if ~all(isvector(a) > 1), d=dim; end 
  s=cell(1,numel(a));
  parfor index=1:numel(a)  % get all axes for a given dimension, in object array
    sx=getaxis(a(index),d);
    if isempty(sx), sx=index;
    elseif isvector(sx), sx=sx(:); end
    s{index}=sx;
  end
  dx=getaxis(a(1),num2str(d));
  if isempty(dx)
    dx=[ 'Axis_' num2str(d) ];
  end
  if isvector(s{1}) % catenate the axes (for dim 'd')
    sx = cat(1, s{:});
  else
    sx = cat(dim, s{:});
  end
  setaxis(b, d, dx, sx);
  clear sx s
  
  if ~all(isvector(a) > 1), break; end
end

b.Command=cmd;
b = iData_private_history(b, mfilename, dim, a(1), a(2));

% reset warnings during interp
iData_private_warning('exit', mfilename);


