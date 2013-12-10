function edit(a)
% edit(s) : edit iData object Signal/Monitor
%
%   @iData/edit function to view the Signal/Monitor of a data set. 
%     The data appears as a spreadsheet (requires Java to be enabled).
%     The Signal can not (yet) be modified.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex:     b=edit(a);
%
% Version: $Revision: 1035 $
% See also iData, iData/uminus, iData/abs, iData/real, iData/imag, iData/uplus

  if numel(a) > 1
    parfor index=1:numel(a)
      edit(a(index));
    end
    return
  end

  if exist('uitable')
    if prod(size(a)) > 1e5
      iData_private_warning(mfilename, [ 'Object ' a.Tag ' is too large (numel=' num2str(prod(size(a))) ...
    '.\n\tYou should rebin with e.g. a=a(1:2:end, 1:2:end, ...).' ]);
    end
    UserData.Monitor = real(get(a,'Monitor'));
    UserData.Signal  = getaxis(a, 'Signal'); % Signal/Monitor
    UserData.Selected= [];
    % opens a Table with the Signal content there-in
    NL = sprintf('\n');
    f = figure('Name', [ 'Edit ' char(a) ]); % raw Signal, no monitor weightening
    p = get(f, 'Position');
    h = uitable('Data', UserData.Signal);
    set(h, 'Position', [0,0,p(3),p(4)]); 
    try
      set(h, 'Tag',[ mfilename '_' a.Tag ]);
      set(h, 'Units','normalized');
      set(h, 'Position', [0,0,1,1]);
      set(h, 'UserData', UserData);  % contains the selection indices
    end

%      'CellEditCallback', @iData_edit_CellEditCallback, , ...
%      'CellSelectionCallback', @iData_edit_CellSelectionCallback, ...
%      'RearrangeableColumn','on', 'ColumnEditable', true, ...
%      'ToolTipString', [ char(a) NL 'You may edit the Signal from the object.' ...
%         NL 'The Contextual menu enables to plot a selection of the oject' ], ...    
    
    % attach contextual menu
    uicm = uicontextmenu; 
    S=a.Source; T=a.Title;
    if length(T) > 23, T=[ T(1:20) '...' ]; end
    if length(S) > 23, S=[ '...' S(end-20:end) ]; end
    uimenu(uicm, 'Separator','on', 'Label', [ 'Title: "' T '"' ]);
    uimenu(uicm, 'Label', [ 'Source: <' S '>' ]);
    uimenu(uicm, 'Label', [ 'Tag: '  a.Tag  ]);
    uimenu(uicm, 'Label', [ 'User: ' a.User ]);
    if ~isempty(a.Label)
      uimenu(uicm, 'Label', [ 'Label: ' a.Label ]);
    end
    if length(getaxis(a))
      uimenu(uicm, 'Separator','on', 'Label', '[Rank]         [Value] [Description]');
      for index=0:length(getaxis(a))
        [v, l] = getaxis(a, num2str(index));
        x      = getaxis(a, index);
        m      = get(a, 'Monitor');
        if index==0 & not(all(m==1 | m==0))
          uimenu(uicm, 'Label', sprintf('%6i %15s  %s [%g:%g] (per monitor)', index, v, l, min(x(:)), max(x(:))));
        else
          uimenu(uicm, 'Label', sprintf('%6i %15s  %s [%g:%g]', index, v, l, min(x(:)), max(x(:))));
        end
      end
    end
    % uimenu(uicm, 'Separator','on','Label','Plot selection...', 'Callback', @iData_edit_display);
    uimenu(uicm, 'Separator','on','Label', 'About iData', 'Callback',[ 'msgbox(''' version(iData) ''')' ]);
    % attach contexual menu to the table
    try
      set(h,   'UIContextMenu', uicm); 
    end
  else
    % open the data file
    try
      edit(a.Source);
    end
  end
end



% function called when the Table is modified: update the initial object
function iData_edit_CellEditCallback(source, eventdata)
  % find initial object, and modify its Signal
  
  % this may be speed-up by only changing the modified elements
  Tag  = get(source, 'Tag');
  Data = get(source, 'Data');
  UD   = get(source, 'UserData');
  try
    Signal = Data.*UserData.Monitor;
  catch
    Signal = Data;
  end
  [caller, base] = findobj(iData, 'Tag', Tag);
  if ~isempty(caller), set(caller, 'Signal', Signal); end
  if ~isempty(base),   set(base,   'Signal', Signal); end
end

% function called when the Table selection is plotted
function iData_edit_display
  h = gcbo; % handle of the Table
  % get the Selection
  
  % plot it (no axes here ?)
  
end

function iData_edit_CellSelectionCallback
  % copy the selection into the UserData
  UserData.Selection = '';
end
