function ResLibCal_UpdateDTau(handle)
% ResLibCal_UpdateDTau(handle): update the current mono/ana d/tau from popup
%
% handle: graphics handle to a popup
  
  if strcmp(get(handle,'style'),'popupmenu')
    % get the choice, then the Tau value, and update 'edit' uicontrol
    choices = get(handle,'String');
    index   = get(handle,'Value');
    tag     = get(handle,'Tag');
    if     ~isempty(strfind(tag,'mono')), tag = 'EXP_mono_d';
    elseif ~isempty(strfind(tag,'ana')),  tag = 'EXP_ana_d'; 
    else return; 
    end
    if exist('GetTau') == 2
      tau = GetTau(strtok(choices{index},' '));
      if isempty(tau), 
        disp([ mfilename ': can not find tau for "' strtok(choices{index},'" ') ])
        return; 
      end
      handle = findall(gcbf, 'Tag', tag);
      set(handle,'String', num2str(2*pi/tau));
    else
      disp([mfilename ': ResLib 3.4/GetTau is not available' ]);
    end
  end
