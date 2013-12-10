function f_signal = iData_interp(i_axes, i_signal, f_axes, method)
% iData_interp: private function for interpolation
% interpolates i_signal(i_axes{}) onto f_axes{} and returns the f_signal
%
% arguments:
%  i_axes:   cell array of initial axes
%  i_signal: initial signal (double array or vector)
%  f_axes:   desired new axes for interpolation (cell array)
%  method:   method used in interpolation
%  f_signal: interpolated new signal (double array)

if isempty(i_signal), f_signal=[]; return; end
if isvector(i_signal) % force axes to be vectors
  for index=1:length(i_axes)
    x=i_axes{index}; x=x(:); i_axes{index}=x;
  end
  clear x
end

switch length(i_axes)
case 1    % 1D
  X=i_axes{1};
  Y=i_signal;
  [X,I] = unique(X); Y=Y(I);
  f_signal = interp1(X,   Y, f_axes{1},   method, NaN);
otherwise % nD, n>1
  if length(i_signal) <= 1  % single value ?
    f_signal = i_signal;
    return
  end
  if isvector(i_signal)  % long vector nD Data set
    if length(i_axes) == 2
      if ~any(strcmp(method,{'linear','nearest','cubic','v4','natural'})), method='linear'; end
      f_signal = griddata(i_axes{[2 1]}, i_signal, f_axes{[2 1]}, method);
    else                       % method: linear or nearest
      if ~any(strcmp(method,{'linear','nearest'})), method='linear'; end
      % i_axes and f_axes must be columns, and cell2mat append them for
      % griddatan
      for index=1:length(i_axes)
        x = i_axes{index}; i_axes{index}=x(:); 
        x = f_axes{index}; f_axes{index}=x(:); clear x;
      end
      f_signal = griddatan(cell2mat(i_axes), i_signal, cell2mat(f_axes), method);
    end
  else
    % f_axes must be an ndgrid result, and monotonic
    if ~any(strcmp(method,{'linear','nearest','cubic','spline'})), method='linear'; end
    for i=1:length(i_axes); v=i_axes{i};  if numel(v) == length(v), i_axes{i}=v(:); end; end
    f_signal = interpn(i_axes{:}, i_signal, f_axes{:}, method, NaN);
  end
end
