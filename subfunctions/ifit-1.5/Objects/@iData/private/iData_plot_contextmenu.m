function iData_plot_contextmenu(a, h, xlab, ylab, zlab,  T, S, d, cmd)
% iData_plot_contextmenu: add a contextmenu to the iData plot
% used in iData/plot

% contextual menu for the single object being displayed
% internal functions must be avoided as it uses LOTS of memory
uicm = uicontextmenu; 
% menu About
uimenu(uicm, 'Label', [ 'About ' a.Tag ': ' num2str(ndims(a)) 'D object ' mat2str(size(a)) ' ...' ], ...
  'Callback', [ 'msgbox(getfield(get(get(gco,''UIContextMenu''),''UserData''),''properties''),' ...
                '''About: Figure ' num2str(gcf) ' ' T ' <' S '>'',' ...
                '''custom'',getfield(getframe(gcf),''cdata''), get(gcf,''Colormap''));' ] );

% menu Toggle error bars (1D object)
if ndims(a) == 1
  uimenu(uicm, 'Label','Toggle Error Bars', 'Callback', [...
   'tmp_h=get(gco,''children'');'...
   'if strcmp(get(tmp_h(2),''visible''),''off''), tmp_v=''on''; else tmp_v=''off''; end;' ...
   'set(tmp_h(2),''visible'',tmp_v); clear tmp_h tmp_v' ]);
end
uimenu(uicm, 'Separator','on', 'Label', [ 'Title: "' T '" ' d ]);
if exist(a.Source,'file') && ~isdir(a.Source)
  uimenu(uicm, 'Label', [ 'Source: <' S '>' ], 'Callback',[ 'edit(''' a.Source ''')' ]);
else
  uimenu(uicm, 'Label', [ 'Source: <' S '>' ]);
end
if ~isempty(d)
  uimenu(uicm, 'Label', [ 'Label: ' d ]);
end
% menu List of Commands (history)
uimenu(uicm, 'Label', [ 'Cmd: ' cmd ' ...' ], 'Callback', [ ...
 'tmp_ud = get(get(gco,''UIContextMenu''),''UserData'');' ...
 'listdlg(''ListString'', getfield(tmp_ud, ''commands''),' ...
  '''ListSize'',[400 300],''Name'', tmp_ud.title ,''PromptString'', tmp_ud.name );clear tmp_ud' ])
uimenu(uicm, 'Label', [ 'User: ' a.User ]);

% make up title string and Properties dialog content
properties={ [ 'Data ' a.Tag ': ' num2str(ndims(a)) 'D object ' mat2str(size(a)) ], ...
             [ 'Title: "' char(T) '" ' d ], ...
             [ 'Source: ' a.Source ], ...
             [ 'Last command: ' cmd ]};

properties{end+1} = '[Rank]         [Value] [Description]';
uimenu(uicm, 'Separator','on', 'Label', '[Rank]         [Value] [Description]');
for index=0:length(getaxis(a))
  [v, l] = getaxis(a, num2str(index));
  if length(l) > 20, l = [l(1:18) '...' ]; end 
  x      = getaxis(a, index);
  m      = get(a, 'Monitor');
  if length(x) == 1
    minmaxstd = sprintf('[%g]', full(x));
  elseif isvector(x)
    minmaxstd = sprintf('[%g:%g] length [%i]', full(min(x)), full(max(x)),length(x));
  else
    x=x(:);
    minmaxstd = sprintf('[%g:%g] size [%s]', full(min(x)), full(max(x)),num2str(size(x)));
  end
  if index==0
    if not(all(m==1 | m==0))
      minmaxstd=[ minmaxstd sprintf(' (per monitor=%g)', mean(m(:))) ];
    end
    minmaxstd=[ minmaxstd sprintf(' sum=%g', sum(iData_private_cleannaninf(x))) ];
  end
  if prod(size(a)) < 1e4
    try
      [s, f] = std(a, index);
      minmaxstd=[ minmaxstd sprintf(' <%g +/- %g>', f,s) ];
    end
  end
  t = sprintf('%6i %15s  %s %s', index, v, l, minmaxstd);
  properties{end+1} = t;
  uimenu(uicm, 'Label', t);
  clear x m
end
% menu About iFit
uimenu(uicm, 'Separator','on','Label', 'About iFit/iData', 'Callback', ...
  [ 'msgbox(''' version(iData,2) sprintf('. Visit <http://ifit.mccode.org>') ''',''About iFit'',''help'')' ]);
% attach contexual menu to plot with UserData storage
ud.properties=properties;
ud.xlabel = xlab;
ud.ylabel = ylab;
ud.zlabel = zlab;
ud.title  = T;
ud.name   = char(a);
ud.commands = commandhistory(a);
ud.handle = h;

set(uicm,'UserData', ud);
set(h,   'UIContextMenu', uicm); 

% contextual menu for the axis frame
if ~isempty(get(gca, 'UserData'))
  ud = get(gca, 'UserData');
end
uicm = uicontextmenu;
% menu Duplicate (axis frame/window)
uimenu(uicm, 'Label', 'Duplicate View...', 'Callback', ...
   [ 'tmp_cb.g=gca; tmp_cb.ud=get(gca,''UserData'');' ...
     'tmp_cb.f=figure; tmp_cb.c=copyobj(tmp_cb.g,gcf); ' ...
     'set(tmp_cb.c,''position'',[ 0.1 0.1 0.85 0.8]);' ...
     'set(gcf,''Name'',''Copy of ' strrep(char(a),'''','"') '''); ' ...
     'set(gca,''XTickLabelMode'',''auto'',''XTickMode'',''auto'');' ...
     'set(gca,''YTickLabelMode'',''auto'',''YTickMode'',''auto'');' ...
     'set(gca,''ZTickLabelMode'',''auto'',''ZTickMode'',''auto'');' ...
     'title(tmp_cb.ud.title);', ...
     'xlabel(tmp_cb.ud.xlabel);ylabel(tmp_cb.ud.ylabel); clear tmp_cb;']);
     
if ndims(a) == 1 && ~isfield(ud,'contextual_1d')
  ud.contextual_1d = 1;
end
% menu Toggle all error bars (axis)
if isfield(ud,'contextual_1d') && ud.contextual_1d==1
  uimenu(uicm, 'Label','Toggle All Error Bars', 'Callback', [ ... 
    'tmp_hg = findobj(gca,''type'',''hggroup'');tmp_v=[];'...
    'for tmp_i=1:length(tmp_hg)'...
    'tmp_h=get(tmp_hg(tmp_i),''children'');'...
    'if isempty(tmp_v) ' ...
    'if strcmp(get(tmp_h(2),''visible''),''off''), tmp_v=''on''; else tmp_v=''off''; end;' ...
    'end; set(tmp_h(2),''visible'',tmp_v); clear tmp_h;' ...
    'end; clear tmp_hg tmp_i tmp_v;' ...
   ]);
end
uimenu(uicm, 'Label','Toggle grid', 'Callback','grid');
if ndims(a) >= 2 && ~isfield(ud,'contextual_2d')
  ud.contextual_2d = 1;
end
if isfield(ud,'contextual_2d') && ud.contextual_2d==1
  uimenu(uicm, 'Label','Reset Flat/3D View', 'Callback', [ ...
    '[tmp_a,tmp_e]=view; if (tmp_a==0 & tmp_e==90) view(3); else view(2); end;' ...
    'clear tmp_a tmp_e; lighting none;alpha(1);shading flat;rotate3d off;axis tight;' ]);
  uimenu(uicm, 'Label','Smooth View','Callback', 'shading interp;');
  uimenu(uicm, 'Label','Add Light','Callback', 'light;lighting phong;');
  uimenu(uicm, 'Label','Transparency','Callback', 'for tmp_h=get(gca, ''children'')''; try; alpha(tmp_h,0.7*get(tmp_h, ''facealpha'')); end; end');
  uimenu(uicm, 'Label','Linear/Log scale','Callback', 'if strcmp(get(gca,''zscale''),''linear'')  set(gca,''zscale'',''log''); else set(gca,''zscale'',''linear''); end');
  uimenu(uicm, 'Label','Toggle Perspective','Callback', 'if strcmp(get(gca,''Projection''),''orthographic'')  set(gca,''Projection'',''perspective''); else set(gca,''Projection'',''orthographic''); end');
else
  uimenu(uicm, 'Label','Reset View', 'Callback','view(2);lighting none;alpha(1);shading flat;axis tight;rotate3d off;');
  uimenu(uicm, 'Label','Linear/Log scale','Callback', 'if strcmp(get(gca,''yscale''),''linear'')  set(gca,''yscale'',''log''); else set(gca,''yscale'',''linear''); end');
end

uimenu(uicm, 'Separator','on','Label', 'About iFit/iData', ...
  'Callback',[ 'msgbox(''' version(iData,2) sprintf('. Visit <http://ifit.mccode.org>') ''',''About iFit'',''help'')' ]);
set(gca, 'UIContextMenu', uicm);
set(gca, 'UserData', ud);

% add rotate/pan/zoom tools to the figure in case java machine is not started
if ~usejava('jvm')
  uicmf = uicontextmenu;
  uimenu(uicmf, 'Label','Zoom on/off', 'Callback','zoom');
  uimenu(uicmf, 'Label','Pan on/off',  'Callback','pan');
  if ndims(a) >= 2
    uimenu(uicmf, 'Label', 'Rotate on/off', 'Callback','rotate3d');
  end
  uimenu(uicmf, 'Label','Legend on/off', 'Callback','legend(gca, ''toggle'',''Location'',''Best'');');
  uimenu(uicmf, 'Label','Print...', 'Callback','printpreview');
  set(gcf, 'UIContextMenu', uicmf);
  set(gcf, 'KeyPressFcn', @(src,evnt) eval('if lower(evnt.Character)==''r'', lighting none;alpha(1);shading flat;axis tight;rotate3d off; zoom off; pan off; end') );
end


