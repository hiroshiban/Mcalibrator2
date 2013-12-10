function fig = ResLibCal_EXP2fig(EXP, fig)
% fig=ResLibCal_EXP2fig(EXP): send EXP to main ResLibCal window
%
% sends the content of a ResLib EXP structure into the ResLibCal figure.
%  when the figure does not exist, it is opened.
%
% Return:
%  fig: handle of the ResLibCal interface

% Calls: none (ResLibCal_field2fig inline)

  % find main figure
  if nargin == 0, return; end
  if nargin < 2, fig=''; end
  if ~isstruct(EXP), return; end
  if ishandle(fig), 
    if ~strcmp(get(fig, 'Tag'),'ResLibCal'), fig = ''; end
  else fig = ''; 
  end
  if isempty(fig), fig=findall(0, 'Tag','ResLibCal'); end
  if isempty(fig), return; end
  
  % check EXP structure. Perhaps it is a full ResLibCal structure
  if isfield(EXP,'EXP')
    EXP = EXP.EXP;
  end

  % from ResLib/MakeExp A. Zheludev, 1999-2006 ---------------------------------
  
  %-------------------------   Computation type    -----------------------------
  if isfield(EXP,'method')
    if ischar(EXP.method), 
      methods = get(findobj(fig, 'Tag','EXP_method'),'String');
      EXP.method = find(strcmp(EXP.method, methods));
      if ~isempty(EXP.method), EXP.method = EXP.method-1; 
      else EXP.method=0; end
    end
    if isempty(EXP.method), EXP.method=0; end
    set(findobj(fig,'Tag','EXP_method'),'Value', EXP.method+1); 
  end
  
  if isfield(EXP,'mono')
    if     isfield(EXP.mono,'d')   EXP.mono.tau = 2*pi/EXP.mono.d;
    elseif isfield(EXP.mono,'tau') EXP.mono.d   = 2*pi/EXP.mono.tau; end
  end
  if isfield(EXP,'ana')
    if     isfield(EXP.ana,'d')   EXP.ana.tau = 2*pi/EXP.ana.d;
    elseif isfield(EXP.ana,'tau') EXP.ana.d   = 2*pi/EXP.ana.tau; end
  end

  %-------------------------   Monochromator and analyzer    -------------------
  ResLibCal_field2fig(EXP, 'EXP_mono_d', fig);
  ResLibCal_field2fig(EXP, 'EXP_mono_mosaic', fig);
  ResLibCal_field2fig(EXP, 'EXP_mono_vmosaic', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_d', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_mosaic', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_vmosaic', fig);

  %-------------------------   Sample ------------------------------------------
  if isfield(EXP, 'sample')
    if isfield(EXP.sample,'a') && isfield(EXP.sample,'b') && isfield(EXP.sample,'c')
      set(findobj(fig,'Tag','EXP_sample_abc'),'String', ...
        sprintf('%g ', [ EXP.sample.a EXP.sample.b EXP.sample.c ]));
    end
    if isfield(EXP.sample,'alpha') && isfield(EXP.sample,'beta') && isfield(EXP.sample,'gamma')
      set(findobj(fig,'Tag','EXP_sample_alphabetagamma'),'String', ...
        sprintf('%g ', [ EXP.sample.alpha EXP.sample.beta EXP.sample.gamma ]));
    end
    ResLibCal_field2fig(EXP, 'EXP_sample_mosaic', fig);
    ResLibCal_field2fig(EXP, 'EXP_sample_vmosaic', fig);
  end

  %-------------------------   Soller and neutron guide collimation    ---------
  table = get(findobj(fig,'Tag','EXP_collimators'),'Data');
  if isfield(EXP,'hcol'), table(1,:) = EXP.hcol; end
  if isfield(EXP,'vcol'), table(2,:) = EXP.vcol; end
  if isfield(EXP,'arms'), table(3,:) = EXP.arms(1:4); end
  set(findobj(fig,'Tag','EXP_collimators'),'Data', table);

  %-------------------------   Fixed neutron energy    -------------------------
  ResLibCal_field2fig(EXP, 'EXP_efixed', fig);
  ResLibCal_field2fig(EXP, 'EXP_Kfixed', fig);
  ResLibCal_field2fig(EXP, 'EXP_Lfixed', fig);
  if isfield(EXP,'fx')
    set(findobj(fig,'Tag','EXP_Kf_button'),'Value', (EXP.fx == 2));
    set(findobj(fig,'Tag','EXP_Ki_button'),'Value', (EXP.fx == 1));
  else
    set(findobj(fig,'Tag','EXP_Kf_button'),'Value', (EXP.infin == -1));
    set(findobj(fig,'Tag','EXP_Ki_button'),'Value', (EXP.infin ==  1));
  end

  %-------------------------   Experimental geometry    ------------------------
  % value sm,sa,ss: +1:left, -1=right
  if     isfield(EXP.mono,  'dir') sm=EXP.mono.dir; 
  elseif isfield(EXP,'mondir')     sm=EXP.mondir;
  else                             sm=1;
  end
  % EXP.dir1/dir2: 1=opposite to previous element, -1=same as previous
  if isfield(EXP.sample,'dir') ss= EXP.sample.dir; 
  elseif isfield(EXP,'dir1')   ss=-sm*EXP.dir1;
  end
  if isfield(EXP.ana,'dir')    sa= EXP.ana.dir; 
  elseif isfield(EXP,'dir2')   sa=-ss*EXP.dir2;
  end
  % transfer to popup
  % Value Popup: 1=right -> -1 (clock) : 2=left -> +1
  set(findobj(fig,'Tag','EXP_mono_dir'),  'Value',(sm==-1)+2*(sm==1));
  set(findobj(fig,'Tag','EXP_sample_dir'),'Value',(ss==-1)+2*(ss==1));
  set(findobj(fig,'Tag','EXP_ana_dir'),   'Value',(sa==-1)+2*(sa==1));
  
  ResLibCal_field2fig(EXP, 'EXP_orient1', fig);
  ResLibCal_field2fig(EXP, 'EXP_orient2', fig);

  %-------------------------   Spatial parameters     --------------------------
  ResLibCal_field2fig(EXP, 'EXP_beam_width', fig);
  ResLibCal_field2fig(EXP, 'EXP_beam_height', fig);
  ResLibCal_field2fig(EXP, 'EXP_detector_width', fig);
  ResLibCal_field2fig(EXP, 'EXP_detector_height', fig);
  ResLibCal_field2fig(EXP, 'EXP_mono_width', fig);
  ResLibCal_field2fig(EXP, 'EXP_mono_height', fig);
  ResLibCal_field2fig(EXP, 'EXP_mono_depth', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_width', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_height', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_depth', fig);
  ResLibCal_field2fig(EXP, 'EXP_sample_width', fig);
  ResLibCal_field2fig(EXP, 'EXP_sample_depth', fig);
  ResLibCal_field2fig(EXP, 'EXP_sample_height', fig);

  % Crystal curvatures
  ResLibCal_field2fig(EXP, 'EXP_mono_rv', fig);
  ResLibCal_field2fig(EXP, 'EXP_mono_rh', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_rv', fig);
  ResLibCal_field2fig(EXP, 'EXP_ana_rh', fig);
  %-------------------------   Horizontally focusing analyzer  -----------------
  if isfield(EXP, 'horifoc') && EXP.horifoc==-1
    set(findobj(fig,'Tag','EXP_ana_rh'),'String','0');
  end
  
  % current HKLW position
  ResLibCal_field2fig(EXP, 'EXP_QH', fig);
  ResLibCal_field2fig(EXP, 'EXP_QK', fig);
  ResLibCal_field2fig(EXP, 'EXP_QL', fig);
  ResLibCal_field2fig(EXP, 'EXP_W' , fig);
% end ResLibCal_EXP2fig

% ==============================================================================
function ResLibCal_field2fig(EXP, field, fig)
% ResLibCal_field2fig(EXP, field): send a single field from EXP to the figure
%
% used by ResLibCal_EXP2fig (below)
 
  if ~isstruct(EXP) || isempty(field), return; end
  
  tag = '';
  if strncmp(field, 'EXP', 3)
    if any(field == '_') % we have a Tag name
      tag = field; field = strrep(field, '_','.');
    elseif any(field == '.')
      tag = strrep(field, '.','_');
    end
  end
  % check that both tag and field exist
  hObject = findobj(fig, 'Tag', tag);
  if ~isempty(hObject)
    try
      value = num2str(eval(field));
    catch
      warning([ mfilename ': Can not get field ' field ]);
      value = '';
    end
    if isempty(value), return; end
    if length(hObject) > 1
      warning([ mfilename ': Tag ' tag ' is duplicated.' ]);
    end
    try
      set(hObject(1), 'String', num2str(value)); 
    catch
      warning([ mfilename ': Can not set Tag ' tag ' String property to ' value ]);
    end
  else
    warning([ mfilename ': Can not find Tag ' tag ]);
  end
% end ResLibCal_field2fig

