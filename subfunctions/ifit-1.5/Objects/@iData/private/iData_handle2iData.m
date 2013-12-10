% iData_handle2iData: converts a numeric into an iData
function out=iData_handle2iData(in)
  try 
    t = get(in,'DisplayName');
    if isempty(t), t=get(get(in,'Parent'),'DisplayName'); end
  catch
    t=[]; end
  if isempty(t), t=get(in,'Tag'); end
  if isempty(t), t=num2str(in); end
  if strcmp(get(in,'type'),'hggroup')
    t = [ 'figure ' t ];
    h = get(in,'Children');
    out = iData(h(1)); % first item
    out.Title=t;
    out.Label=t;
  elseif strcmp(get(in,'type'),'line')
    x = get(in,'xdata'); 
    y = get(in,'ydata'); 
    index = find(~isnan(x) & ~isnan(y));
    if length(index)~=numel(x), x = x(index); y=y(index); end
    c = get(in,'color');
    m = get(in,'marker');
    l = get(in,'linestyle');
    out=iData(x,y);
    try xl = get(get(in,'parent'),'XLabel'); xl=get(xl,'String'); catch 
        xl='x'; end; xlabel(out, xl);
    try yl = get(get(in,'parent'),'YLabel'); yl=[ get(yl,'String') ' ' ]; catch 
        yl=''; end;
    try tl = get(get(in,'parent'),'Title');  tl=[ get(tl,'String') ' ' ]; catch 
        tl=''; end;
    label(out,0,yl);
    t = [ 'line ' t ];
    out.Title = [ tl yl t ];
    out.DisplayName = t;
    out.Label=[ t ' marker ' m ' color ' num2str(c) ];
  elseif strcmp(get(in,'type'),'image')
    x = get(in,'xdata'); 
    y = get(in,'ydata');
    z = get(in,'cdata');
    t = [ 'image ' t ];
    out=iData(x,y,z);
    try xl = get(get(in,'parent'),'XLabel'); xl=get(xl,'String'); catch 
        xl='x'; end
    try yl = get(get(in,'parent'),'YLabel'); yl=get(yl,'String'); catch 
        yl='y'; end
    try zl = get(get(in,'parent'),'ZLabel'); zl=[ get(zl,'String') ' ' ]; catch 
        zl=''; end 
    try tl = get(get(in,'parent'),'Title');  tl=[ get(tl,'String') ' ' ]; catch 
        tl=''; end
    xlabel(out, xl); ylabel(out, yl); label(out, tl);
    out.Title = t;
    out.DisplayName = t;
    out.Label=t;
  elseif strcmp(get(in,'type'),'surface')
    x = get(in,'xdata'); 
    y = get(in,'ydata'); 
    z = get(in,'zdata'); 
    c = get(in,'cdata'); 
    % index=find(~isnan(x) & ~isnan(y) & ~isnan(z) & ~isnan(c)); 
    % if length(index)~=prod(size(x)), x = x(index); y=y(index); z=z(index); c=c(index); end
    l = get(in,'linestyle');
    if all(z == c)
      out=iData(x,y,z);
    else
      out=iData(x,y,z,c);
    end
    try 
        xl = get(get(in,'parent'),'XLabel'); xl=get(xl,'String'); 
    catch 
        xl='x'; end
    try 
        yl = get(get(in,'parent'),'YLabel'); yl=get(yl,'String'); 
    catch
        yl='y'; end
    try 
        zl = get(get(in,'parent'),'ZLabel'); zl=[ get(zl,'String') ' ' ]; 
    catch 
        zl=''; end 
    try 
        tl = get(get(in,'parent'),'Title');  tl=[ get(tl,'String') ' ' ]; 
    catch 
        tl=''; end

    xlabel(out, xl); ylabel(out, yl); label(out, tl);
    if all(z == c)
      t = [ tl zl t ];
    else
      if isempty(zl), zl='z'; end
      zlabel(out, zl);
      t = [ tl t ];
    end
    t = [ 'surface ' t ];
    out.Title = t;
    out.DisplayName = t;
    out.Label=[ t ' line ' l ];
  else
    h = [ findobj(in, 'type','line') ; findobj(in, 'type','surface') ; findobj(in, 'type','image')  ];
    out = [];
    for index=1:length(h)
      this_out = iData(h(index));
      if isempty(this_out.Title) && ~isempty(t)
        this_out.Title = t;
        this_out.Label = t;
        this_out.DisplayName = t;
      end
      if ~isempty(t), this_out.Source = t; end
      if  ~isscalar(get(this_out,'Signal'))
        out = [ out this_out ];
      end
    end
  end
% ------------------------------------------------------------------------------
