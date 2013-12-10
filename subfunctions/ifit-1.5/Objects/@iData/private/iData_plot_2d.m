function [h, xlab, ylab, zlab] = iData_plot_2d(a, method, this_method, varargin)
% iData_plot_2d: plot a 2D iData object
% used in iData/plot

% check if a re-grid is needed
  if isvector(a)
    a_is_vector = 1; % plot as lines
  elseif (~isvector(a) && (~isempty(strfind(method,'plot3')) || ~isempty(strfind(method,'scatter')) ))
    a = meshgrid(a);
    a_is_vector = 1; % plot as lines, even after re-sampling (requested explicitly)
  else
    a_is_vector = 0;
  end
  [x, xlab] = getaxis(a,2);
  [y, ylab] = getaxis(a,1);
  [z, zlab] = getaxis(a,0);
  m         = get(a,'Monitor');
  if not(all(m(:) == 1 | m(:) == 0)),
    zlab = [zlab ' per monitor' ];
  end
  x=real(double(x));
  y=real(double(y));
  z=real(double(z));
  if a_is_vector % plot3/fscatter3
    if (strfind(method,'scatter'))
      h=fscatter3(x(:),y(:),z(:),z(:),this_method); view(3);
    else
      if length(method), h = plot3(x,y,z, this_method, varargin{:});
      else h = plot3(x,y,z, varargin{:}); end
    end
  else                % surf and similar stuff
    C = [];
    if isvector(x) & isvector(y),
      z = z;
    end
    if (strfind(method,'contour3'))
      [C,h]=contour3(x,y,z, varargin{:});
    elseif (strfind(method,'contourf'))
      [C,h]=contourf(x,y,z, varargin{:});
    elseif (strfind(method,'contour'))
      if isempty(getaxis(a,3))
        [C,h]=contour(x,y,z, varargin{:});
      else
        % display contour in a non-zero plane
        c=getaxis(a,3); c=mean(c(:));
        Z(:,:,1)=z; Z(:,:,2)=z; Z(:,:,3)=z;
        h=contourslice(x,y,[c*0.999 c c*1.001],Z,[],[],c, varargin{:});
      end
    elseif (strfind(method,'surfc'))
      h    =surfc(x,y,z); % set(h,'Edgecolor','none');
    elseif (strfind(method,'surfl'))
      h    =surfl(x,y,z); set(h,'Edgecolor','none');
    elseif (strfind(method,'mesh'))
      h    =mesh(x,y,z);
    elseif ~isempty(strfind(method,'pcolor')) || ~isempty(strfind(method,'image'))
      h    =pcolor(x,y,z); set(h,'Edgecolor','none');
      if ~isempty(getaxis(a,3))
        c=getaxis(a,3); c=mean(c(:));
        zh= get(h,'ZData'); zh=ones(size(zh))*c;
        set(h,'ZData',zh);
      end
    elseif (strfind(method,'stem'))
      if length(method), h = stem3(x,y,z, this_method);
      else h = stem3(x,y,z); end
    elseif (strfind(method,'plot3'))
      a = meshgrid(a);
      if length(method), h = plot3(x(:),y(:),z(:), this_method);
      else h = plot3(x,y,z); end
    elseif (strfind(method,'scatter'))
      h=fscatter3(x(:),y(:),z(:),z(:),this_method);
    elseif (strfind(method,'waterfall'))
      h=waterfall(x,y,z);
    else
      h=surf(x,y,z); set(h,'Edgecolor','none');
    end

    if ~isempty(C) & strfind(method,'clabel')
      clabel(C,h);
    end
  end
  zlabel(zlab);
