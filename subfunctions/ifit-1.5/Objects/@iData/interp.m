function b = interp(a, varargin)
% [b...] = interp(s, ...) : interpolate iData object
%
%   @iData/interp function to interpolate data sets.
%
%   The multidimensional interpolation is based on a Delauney tessellation 
%     using the Computational Geometry Algorithms Library, CGAL.
%   This function computes the values of the object 's' interpolated
%   on a new axis grid, which may be specified from an other object, as independent axes,
%   or as a rebinning of the original axes.
%     b=interp(s)    rebin/check 's' on a regular grid.
%     b=interp(s, d) where 'd' is an iData object computes 's' on the 'd' axes.
%     b=interp(s, X1,X2, ... Xn) where 'Xn' are vectors or matrices as obtained 
%                    from ndgrid computes 's' on these axes.
%     b=interp(s, {X1,X2, ... Xn}) is similar to the previous syntax
%     b=interp(s, ..., ntimes) where 'ntimes' is an integer computes new axes for 
%                    interpolation by sub-dividing the original axes ntimes.
%                    we also recommend the 'resize' method (much faster).
%     b=interp(s, ..., 'method') uses specified method for interpolation as one of
%                    linear (default), spline, cubic, or nearest
%     b=interp(s, ..., 'grid') uses meshgrid/ndgrid to determine new axes as arrays
%   Extrapolated data is set to NaN for the Signal, Error and Monitor.
%   For Event data sets, we recommend to use the 'hist' method.which is much faster.
%
% input:  s: object or array (iData)
%         d: single object from which interpolation axes are extracted (iData)
%            or a cell containing axes d={X1,X2, ... Xn}               (cell)
%         X1...Xn: scalar, vectors or matrices specifying axis for 
%            dimensions 1 to ndims(s) (double scalar/vector/matrix)
%         ntimes: original axis sub-division (integer)
% output: b: object or array (iData)
% ex:     a=iData(peaks); b=interp(a, 'grid'); c=interp(a, 2);
%
% Version: $Revision: 1133 $
% See also iData, interp1, interpn, ndgrid, iData/setaxis, iData/getaxis, 
%          iData/hist, iData/resize, iData/reshape

% iData_interp and iData_meshgrid are in private

% input: option: linear, spline, cubic, nearest
% axes are defined as rank of matrix dimensions
% plot function is plot(y,x,Signal)
% rand(10,20) 10 rows, 20 columns
% pcolor/surf with view(2) shows x=1:20, y=1:10

% handle input iData arrays
if numel(a) > 1
  b = zeros(iData, numel(a), 1);
  parfor index=1:numel(a)
    b(index) = interp(a(index), varargin{:});
  end
  b = reshape(b, size(a));
  return
end

% build new iData object to hold the result
b = copyobj(a);

% object check
if ndims(a) == 0
  iData_private_warning(mfilename,['Object ' inputname(1) ' ' a.Tag ' is empty. Nothing to interpolate.']);
  return
end
% removes warnings during interp
iData_private_warning('enter', mfilename);
warning('off','MATLAB:griddata:DuplicateDataPoints');

% default axes/parameters
i_axes = cell(1,ndims(a)); i_labels=i_axes;
parfor index=1:ndims(a)
  [i_axes{index}, i_labels{index}] = getaxis(a, index);  % loads object axes, or 1:end if not defined 
end
parfor index=ndims(a):length(a.Alias.Axis)
  [dummy, i_labels{index}] = getaxis(a, index);  % additional inactive axes labels (used to create new axes)
end
method='linear';
ntimes=0;

% interpolation axes
f_axes           = i_axes;
requires_meshgrid= 0;

% parse varargin to overload defaults and set manually the axes ----------------
axis_arg_index   = 0;
for index=1:length(varargin)
  c = varargin{index};
  if ischar(c) & ~isempty(strfind(c,'grid')) 
    requires_meshgrid=1;
  elseif ischar(c)                      % method (char)
    method = c;
  elseif isa(varargin{index}, 'iData')  % iData object axes
    if length(c) > 1
      iData_private_warning(mfilename,['Can not interpolate onto all axes of input argument ' num2str(index) ' which is an array of ' num2str(numel(c)) ' elements. Using first element only.']);
      c = c(1);
    end
    for j1 = 1:ndims(c)
      axis_arg_index = axis_arg_index+1;
      [f_axes{axis_arg_index}, lab] = getaxis(c, j1);
      if ~isempty(lab) && axis_arg_index < length(i_labels) && isempty(i_labels{axis_arg_index})
        i_labels{axis_arg_index} = lab;
      end
    end
  elseif isnumeric(c) & length(c) ~= 1  % vector/matrix axes
    axis_arg_index = axis_arg_index+1;
    if ~isempty(c), f_axes{axis_arg_index} = c; end
  elseif isnumeric(c) & length(c) == 1  % ntimes rebinning (max 10 times)
    ntimes=c;
    if abs(ntimes) > 10, ntimes=10; end
  elseif iscell(c)                      % cell(vector/matrix) axes
    for j1 = 1:length(c(:))
      axis_arg_index = axis_arg_index+1;
      if ~isempty(c{j1}), f_axes{axis_arg_index} = c{j1}; end
    end
  elseif ~isempty(c)
    iData_private_warning(mfilename,['Input argument ' num2str(index) ' of class ' class(c) ' size [' num2str(size(c)) '] is not supported. Ignoring.']);
  end
  clear c
end % input arguments parsing

b = iData_private_history(b, mfilename, a, varargin{:});
cmd=b.Command;
clear varargin a

% check for method to be valid
if isempty(any(strcmp(method, {'linear','cubic','spline','nearest','v4'})))
  iData_private_warning(mfilename,['Interpolation method ' method ' is not supported. Use: linear, cubic, spline, nearest, v4. Defaulting to linear.']);
  method = 'linear';
end

% check/determine output axes for interpolation --------------------------------

% test axes and decide to call meshgrid if necessary

if isvector(b) >= 2 % plot3/event
  iData_private_warning(mfilename,['This is an Event data set. The "hist" method is highly recommended rather that "interp".']);
  requires_meshgrid=1; 
  if nargin == 1, ntimes=1; end
end

% check final axes
s_dims = size(b); % Signal/object dimensions

parfor index=1:ndims(b)
  v = f_axes{index}; 
  if isempty(v), v= i_axes{index}; end % no axis specified, use the initial one

  % compute the initial axis length
  if isvector(v), a_len = numel(v);
  else            a_len = size( v, index);
  end
  if isvector(b) >= 2 && a_len > prod(size(b))^(1/ndims(b))*2 % event data set
    a_len = prod(size(b))^(1/ndims(b))*2;
  end
  if ntimes > 0 % expand it if requested
    a_len = a_len*ntimes;
  end
  if a_len == 1, a_len = 2; end
  s_dims(index) = a_len;

end

% check if interpolation is indeed required ------------------------------------
if isvector(b) >=2 % event data set: redirect to hist method (accumarray)
  f_axes = iData_meshgrid(f_axes, s_dims, 'vector'); % private function
  b = hist(b, f_axes{:});
  return
% do we need to recompute the final axes ?
elseif length(f_axes) > 1 && (requires_meshgrid || ntimes)
  f_axes = iData_meshgrid(f_axes, s_dims, method); % private function
end

% test if interpolation axes have changed w.r.t input object (for possible quick exit)
has_changed = 0;
for index=1:ndims(b)  
  this_i = i_axes{index}; if isvector(this_i), this_i=this_i(:); end
  this_f = f_axes{index}; if isvector(this_f), this_f=this_f(:); end
  if ~isequal(this_i, this_f)
    % length changed ?
    if length(this_i) ~= length(this_f)
      % not same length
      has_changed=1; 
    elseif prod(size(this_i)) ~= prod(size(this_f)) % nb of elements has changed, including matrix axes ?
      has_changed=1; 
    elseif all(abs(this_i(:) - this_f(:)) > 1e-4*abs(this_i(:) + this_f(:))/2)
      % or axis variation bigger than 0.01 percent anywhere
      has_changed=1;
    end
  end
  clear this_i this_f
end

% get Signal, error and monitor.
i_signal = subsref(b,struct('type','.','subs','Signal'));

% quick exit check based on the Signal
if any(isnan(i_signal(:))), has_changed=1; end
if ~has_changed & ~requires_meshgrid 
  iData_private_warning('exit', mfilename);
  return; 
end

% prepare interpolation Signal, Error, Monitor ---------------------------------
i_class    = class(i_signal); i_signal = double(i_signal);

i_error = getalias(b, 'Error');
if ~isempty(i_error),   
  % check if Error is sqrt(Signal) or a constant
  if strcmp(i_error, 'sqrt(this.Signal)')
    i_error=[];
  elseif isnumeric(i_error) && isscalar(i_error) == 1
    % keep that as a constant value
  else
    % else get the value
    i_error  = subsref(b,struct('type','.','subs','Error'));
  end
  i_error    = double(i_error);
end
  
i_monitor = getalias(b, 'Monitor');
if ~isempty(i_monitor),   
  % check if Monitor is 1 or a constant
  if isnumeric(i_monitor) && isscalar(i_monitor) == 1
    % keep that as a constant value
  else
    % else get the value
    i_monitor  =subsref(b,struct('type','.','subs','Monitor'));
  end
  i_monitor    = double(i_monitor);
end

% check f_axes vector orientation
parfor index=1:ndims(b)
  i_axes{index} = double(i_axes{index});
  f_axes{index} = double(f_axes{index});
  if isvector(f_axes{index})
    % orient the vector along the dimension
    n = ones(1,ndims(b));
    n(index) = numel(f_axes{index});
    if length(n) == 1, n=[ n 1]; end
    f_axes{index}=reshape(f_axes{index},n);
  end
end

% make sure input axes are monotonic. output axes should be OK ------------
i_nonmonotonic=0;
for index=1:ndims(b)
  if ~isempty(find(diff(i_axes{index},1,index) <= 0))
    i_nonmonotonic=index; break;
  end
end

if i_nonmonotonic && length(i_axes) > 1 
  % transform the initial data into individual points, then interpolate on
  % a regular grid
  i_axes_new  = iData_meshgrid(i_axes, size(b));
  % must make sure initial axes given as vector have same length as signal
  flag_ndgrid_needed = 0;
  for index=1:length(i_axes)
    x=i_axes{index}; x=x(:);
    % make sure length(x) == numel(i_signal) for interpolation to work
    if length(x) < numel(i_signal)
      if isempty(length(x) == size(i_signal))
        iData_private_error(mfilename,sprintf('The axis rank %d of length=%d does not match the object %s Signal dimensions %s\n', ...
          index, length(x), a.Tag, mat2str(size(i_signal)) ...
        ));
      else
        flag_ndgrid_needed = 1;
      end
    end
    i_axes{index} = x;  % now a vector...
  end
  % signal is a grid but axes are vectors, axes should also be...
  if flag_ndgrid_needed
    [i_axes{:}] = ndgrid(i_axes{:});
    parfor index=1:length(i_axes)
        i_axes{index} = i_axes{index}(:);
    end
  end

  % interpolate initial data on monotonic initial axes
  i_signal    = iData_interp(i_axes, i_signal(:),  i_axes_new, method);

  if isnumeric(i_error) && length(i_error) > 1, 
    i_error   = iData_interp(i_axes, i_error(:),   i_axes_new, method); 
  end
  if isnumeric(i_monitor) && length(i_monitor) > 1, 
    i_monitor = iData_interp(i_axes, i_monitor(:), i_axes_new, method); 
  end
  i_axes = i_axes_new;
  clear i_axes_new
end

% last test to check if axes have changed ---------------------------------
has_changed = 0;
parfor index=1:ndims(b)    % change to double before interpolation
  i_axes{index}=double(i_axes{index});
  f_axes{index}=double(f_axes{index});
end
for index=1:ndims(b)
  x = i_axes{index}; x=x(:)';
  if ~isequal(i_axes{index}, f_axes{index})
    has_changed = 1;
    break
  end
end
if ~has_changed, 
  iData_private_warning('exit', mfilename);
  return; 
end

% interpolation takes place here ------------------------------------------
f_signal = iData_interp(i_axes, i_signal, f_axes, method);

if isnumeric(i_error) && length(i_error) > 1, 
     f_error = iData_interp(i_axes, i_error,  f_axes, method); 
else f_error = i_error; end
clear i_error
if isnumeric(i_monitor) && length(i_monitor) > 1, 
     f_monitor = iData_interp(i_axes, i_monitor,f_axes, method);
else f_monitor = i_monitor; end
clear i_monitor i_axes

% get back to original Signal class
if ~strcmp(i_class, 'double')
  f_signal = feval(i_class, f_signal);
  f_error  = feval(i_class, f_error);
  f_monitor= feval(i_class, f_monitor);
end

if isvector(i_signal) && size(i_signal,1)==1
    f_signal = transpose(f_signal);
    f_error  = transpose(f_error);
    f_monitor= transpose(f_monitor);
end
clear i_signal

% transfer Data and Axes --------------------------------------------------
b.Data.Signal =f_signal;  clear f_signal
b.Data.Error  =f_error;   clear f_error
b.Data.Monitor=f_monitor; clear f_monitor
for index=1:length(f_axes)
  b.Data.([ 'axis' num2str(index) ]) = f_axes{index};
end

% update new aliases, but remove old axes which are numeric (to free memory)
g = getalias(b);
to_remove=[];
for index=4:length(g)
  if any(strcmp(g{index}, b.Alias.Axis))
    if isnumeric(b.Alias.Values{index})
      to_remove=[ to_remove index ];
    end
  end
end
b.Alias.Values(to_remove) = [];
b.Alias.Names(to_remove)  = [];
b.Alias.Labels(to_remove) = [];
setalias(b,'Signal', 'Data.Signal');
setalias(b,'Error',  'Data.Error');
setalias(b,'Monitor','Data.Monitor');

% clear axes
rmaxis (b);

for index=1:length(f_axes)
  if index <= length(i_labels)
    b=setalias(b,[ 'axis' num2str(index) ], [ 'Data.axis' num2str(index) ], i_labels{index});
  else
    b=setalias(b,[ 'axis' num2str(index) ], [ 'Data.axis' num2str(index) ]);
  end
  b=setaxis (b, index, [ 'axis' num2str(index) ]);
end
b.Command=cmd; 
% final check
b = iData(b);

if isscalar(b), b=double(b); end

% reset warnings during interp
iData_private_warning('exit', mfilename);


