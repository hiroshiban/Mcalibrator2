function [h, xlab, ylab, zlab, ret] = iData_plot_3d(a, method, this_method, varargin)
% iData_plot_3d: plot a 3D iData object
% used in iData/plot

ret = 0;

% first test if this is an image
  if isfield(a.Data,'cdata')
    h=image(a.Data.cdata);
    xlab=''; ylab=''; zlab='';
  else
    % check if a rebining on a grid is required
    if ~isvector(a) && isempty(strfind(method, 'plot3')) && isempty(strfind(method, 'scatter')) 
      a = meshgrid(a); % make sure we get a grid
    end
    [x, xlab] = getaxis(a,2); x=double(x);
    [y, ylab] = getaxis(a,1); y=double(y);
    [z, zlab] = getaxis(a,3); z=double(z);
    [c, clab] = getaxis(a,0); c=double(c);
    m         = get(a,'Monitor');
    if not(all(m(:) == 1 | m(:) == 0)), clab = [clab ' per monitor' ]; end
    if isvector(a) >= 3 || ~isempty(strfind(method, 'scatter')) % plot3-like
      if ~isempty(strfind(method, 'scatter'))
        h=fscatter3(x(:),y(:),z(:),c(:), this_method);     % scatter3: may require meshgrid
      else
        h=plot3(x(:),y(:),z(:), this_method, varargin{:});
      end
      view(3);
    else
      if ~isempty(strfind(method, 'plot3')) % vol3d: does not require meshgrid
        h = vol3d('cdata',c,'texture','3D','xdata',x,'ydata',y,'zdata',z);
        alphamap('vdown'); % make object transparent on borders and solid in center
        h = vol3d(h);
        h = h.handles;
      elseif ~isempty(strfind(method, 'waterfall')) || ~isempty(strfind(method, 'contour'))
        if ~isempty(strfind(method, ' y '))
          iy = linspace(min(y(:)), max(y(:)), 10);
          h = contourslice(x,y,z,c,[],iy,[], varargin{:});
        elseif ~isempty(strfind(method, ' x '))
          ix = linspace(min(x(:)), max(x(:)), 10);
          h = contourslice(x,y,z,c,ix,[],[], varargin{:});
        else
          iz = linspace(min(z(:)), max(z(:)), 10);
          h = contourslice(x,y,z,c,[],[],iz, varargin{:});
        end
      elseif ~isempty(strfind(method, 'slice')) % sliceomatic
        slice(a); h=[];
      else
        % isosurface: require meshgrid
        if ~isempty(strfind(method, 'mean'))
          iso = mean(c(:));
        elseif ~isempty(strfind(method, 'half'))
          iso = (min(c(:))+max(c(:)))/2;
        elseif ~isempty(strfind(method, 'median'))
          iso = median(c(:));
        else
          iso = [];
        end
        try
          if ~isempty(iso), 
            isosurface(x,y,z, c, iso, varargin{:});
          else 
            isosurface(x,y,z, c, varargin{:}); 
          end
          h = findobj(gca,'type','patch');
        catch
          h = plot(a, 'scatter3', varargin{:});
          ret = 1;
        end
      end
    end
    zlabel(zlab);
  end
