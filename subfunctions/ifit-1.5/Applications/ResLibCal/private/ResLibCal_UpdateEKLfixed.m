function ResLibCal_UpdateEKLfixed(handle)
% ResLibCal_UpdateEKLfixed(handle): update the current E/K/lambda value
%
% handle: graphics handle to E/K/lambda fixed 'edit'

  if strcmp(get(handle,'style'),'edit')
    tag     = get(handle,'Tag');
    value   = str2double(get(handle,'String'));
    VS2E = 5.22703725e-6;
    V2K  = 1.58825361e-3;
    % compute E, K and lambda from the modified one
    switch tag
    case 'EXP_efixed'
      E = value; V = sqrt(E/VS2E); K=V2K*V; L=2*pi/K; 
    case 'EXP_Kfixed'
      K = value; L=2*pi/K; V=K/V2K; E=V*V*VS2E;
    case 'EXP_Lfixed'
      L = value; K=2*pi/L; V=K/V2K; E=V*V*VS2E;
    otherwise
      return
    end
    % update uicontrols/edit box
    set(findall(gcbf, 'Tag', 'EXP_efixed'), 'String', num2str(E));
    set(findall(gcbf, 'Tag', 'EXP_Kfixed'), 'String', num2str(K));
    set(findall(gcbf, 'Tag', 'EXP_Lfixed'), 'String', num2str(L));
  end
