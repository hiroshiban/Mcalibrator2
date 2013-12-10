function [h, xlab, ylab, ret] = iData_plot_1d(a, method, this_method, varargin)
% iData_plot_1d: plot a 1D iData object
% used in iData/plot

ret = 0;

if size(a,1) ==1 && size(a,2) > 1
    a = transpose(a);
  end
  [x, xlab] = getaxis(a,1); x=double(x(:));
  [y, ylab] = getaxis(a,0); y=double(y(:));
  e         = get(a,'Error');   e=real(double(e(:)));
  m         = get(a,'Monitor'); m=real(double(m(:)));
  if not(all(m == 1 | m == 0)),
    e=genop(@rdivide,e,m); ylab = [ylab ' per monitor' ];
  end
  y=real(y);
  
  if isempty(method), method='b-'; end
  % handle side-by-side 1D plots
  if ~isempty(strfind(method,'plot3'))    || ~isempty(strfind(method,'stem')) ...
   || ~isempty(strfind(method,'scatter')) || ~isempty(strfind(method,'mesh')) ...
   || ~isempty(strfind(method,'surf') )   || ~isempty(strfind(method,'waterfall'))
  	ax = getaxis(a,2);
  	if isempty(ax)
  		ax = 0;
    end
    if length(ax) == 1
    	ax = ax*ones(size(a));
    end
    % need to create this axis
    setalias(a, 'Axis_2', ax);
    setaxis(a, 2, 'Axis_2');
    h = plot(a, method, varargin{:});
    ret = 1;
  else 
    if all(e == 0) || length(x) ~= length(e)
      if length(this_method)
        try
          h = plot(x,y, this_method, varargin{:});
        catch
          this_method=[];
        end
      end
      if ~length(this_method) h = plot(x,y, varargin{:}); end
    else
      if length(this_method), 
        try
          h = errorbar(x,y,e,this_method, varargin{:});          
        catch
          this_method=[];
        end
      end
      if ~length(this_method) 
        h = errorbar(x,y,e, varargin{:}); 
      end
      if ~isempty(strfind(method, 'hide_err')) || all(abs(e) >= abs(y) | e == 0)
        if length(h) == 1 && length(get(h,'Children') == 2)
          eh = get(h,'Children');
        else eh = h; 
        end
        if length(eh) > 1, set(eh(2), 'Visible','off'); end
      end
    end
  end
