function a=load_mcstas_1d(a)
% function a=load_mcstas_1d(a)
%
% Returns an iData style dataset from a McStas 1d/2d/list monitor file
% as well as simple XYE files
% Some labels are also searched.
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

% inline: load_mcstas_param

if ~isa(a,'iData')
  a = load(iData,a,'McStas 1D');
  return
end

% handle input iData arrays
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index));
  end
  return
end

% Find proper labels for Signal and Axis
a=iData(a);
if isempty(findstr(a,'McStas'))
  warning([ mfilename ': The loaded data set ' a.Tag ' from ' a.Source ' is not a McStas data format.' ]);
  return
end

xlab=''; ylab='';
d = a.Data;
if ~isfield(d,'MetaData'), return; end

if isfield(d,'Attributes') && isfield(d.Attributes,'MetaData') 
  if ~isempty(findfield(a, 'xlabel')) 
    xlab = a.Data.Attributes.MetaData.xlabel;
    xlab(1:max(strfind(xlab,'xlab')+6))='';
  elseif ~isempty(findfield(a, 'x_label')) 
    xlab = a.Data.Attributes.MetaData.x_label;
    xlab(1:max(strfind(xlab,'x_label'))+6)='';
  else xlab='';
  end

  if ~isempty(findfield(a, 'ylabel')) 
    ylab = a.Data.Attributes.MetaData.ylabel;
    ylab(1:max(strfind(ylab,'ylab')+6))='';
  elseif ~isempty(findfield(a, 'y_label')) 
    ylab = a.Data.Attributes.MetaData.y_label;
    ylab(1:max(strfind(ylab,'y_label')+6))='';
  else ylab='';
  end
  
  if ~isempty(findfield(a, 'zlabel')) 
    zlab = a.Data.Attributes.MetaData.zlabel;
    zlab(1:max(strfind(zlab,'zlab')+6))='';
  elseif ~isempty(findfield(a, 'z_label')) 
    zlab = a.Data.Attributes.MetaData.z_label;
    zlab(1:max(strfind(zlab,'z_label')+6))='';
  else zlab='';
  end
 
  if ~isempty(findfield(a, 'component')) 
    label = strtrim(a.Data.Attributes.MetaData.component);
    label(1:length('# component:'))='';
    a.Label = strtrim(label);
    a.Data.Component = strtrim(label);
    setalias(a, 'Component', 'Data.Component','Component name');
  end
  
  if ~isempty(findfield(a, 'Creator'))
    creator = a.Data.Attributes.MetaData.Creator;
    creator(1:length('# Creator:'))='';
    a.Creator=creator; 
  end
  
end
clear d

% check that guessed Signal is indeed what we look for
signal = getalias(a, 'Signal');
if ischar(signal) && ~isempty(strfind(signal, 'MetaData'))
  % biggest field is not the list but some MetaData, search other List 
  % should be 'Data.MataData.variables' or 'Data.I'
  for search = {'Data.I','Data.Sqw','Data.MetaData.variables'}
    if ~isempty(findfield(a,search,'case exact numeric')), signal = search; break; end
  end
  if isempty(signal)
    [match, types, dims] = findfield(s, '', 'numeric');
    if length(match) > 1, signal = match{2}; end
  end
  if ~isempty(signal), setalias(a, 'Signal', signal); end
end

% treat specific data formats 1D, 2D, List for McStas ==========================
if ~isempty(strfind(a.Format,'McStas 1D monitor'))
  xlabel(a, xlab);
  title(a, ylab);
elseif ~isempty(strfind(a.Format,'McStas 2D monitor'))
  % Get sizes of x- and y- axes:
  siz = size(a.Data.MetaData.variables');
  if all(siz < size(getaxis(a,'Signal')))
    siz = size(getaxis(a,'Signal')');
  else
    setalias(a,'Signal','Data.MetaData.variables',zlab);
  end
  lims = a.Data.MetaData.xylimits;
  xax = linspace(lims(1),lims(2),siz(1));
  yax = linspace(lims(3),lims(4),siz(2));

  % set axes

  setalias(a,'y',xax,xlab);
  setalias(a,'x',yax,ylab);

  setalias(a,'I','Signal');
  if ~isempty(findfield(a, 'Error'))
    setalias(a,'Error','Data.MetaData.Errors');
  else setalias(a,'Error',0);
  end
  setalias(a,'E','Error');
  if ~isempty(findfield(a, 'Events')) 
    setalias(a,'N','Data.MetaData.Events');
  end
  setaxis(a,1,'x');
  setaxis(a,2,'y');
elseif ~isempty(strfind(a.Format,'McStas list monitor'))
  % the Signal should contain the List
  list = getalias(a, 'Signal');
  if ischar(list)
    setalias(a, 'List', list, 'List of events');

    % column signification is given by tokens from the ylab
    columns = strread(ylab,'%s','delimiter',' ');
    index_axes = 0;
    for index=1:length(columns)
      setalias(a, columns{index}, [ list '(:,' num2str(index) ')' ]);
      if index==1
        setalias(a, 'Signal', columns{index});
      elseif index_axes < 3
        index_axes = index_axes +1;
        setaxis(a, index_axes, columns{index});
      end
    end
    if ~isfield(a, 'N'), setalias(a, 'N', length(a{0})); end
  end
end

% build the title: 
%   sum(I) sqrt(sum(I_err^2)) sum(N)
if isfield(a, 'E'), e=a.E; else e=0; end
if isfield(a, 'N'), n=a.N; else n=0; end
s = a{0}; 
values = [ sum(s(:)), sqrt(sum(e(:).^2)), sum(n(:)) ];
clear s
t_sum = sprintf(' I=%g I_err=%g N=%g', values);
%   X0 dX, Y0 dY ...
t_XdX = '';
if ndims(a) == 1; ax='X'; else ax = 'YXZ'; end
for index=1:ndims(a)
  [dx,x0]=std(a,index);
  t_XdX = [t_XdX sprintf(' %c0=%g d%c=%g;', ax(index), x0, ax(index), dx) ];
end
a.Title = [ a.Title, t_sum, t_XdX ];
setalias(a,'statistics',  t_XdX,'Center and Gaussian half width');
setalias(a,'values',values,'I I_err N');

% get the instrument parameters
param = load_mcstas_param(a, 'Param');
a.Data.Parameters = param;
setalias(a, 'Parameters', 'Data.Parameters', 'Instrument parameters');

% end of loader

% ------------------------------------------------------------------------------
% build-up a parameter structure which holds all parameters from the simulation
function param=load_mcstas_param(a, keyword)
  if nargin == 1, keyword='Param:'; end
  param = [];

  par_list = findstr(a, keyword);
  % search strings of the form 'keyword' optional ':', name '=' value
  for index=1:length(par_list)
    line         = par_list{index};
    reversed_line= line(end:-1:1);
    equal_sign_id= find(reversed_line == '=');
    name         = fliplr(strtok(reversed_line((equal_sign_id+1):end),sprintf(' \n\t\r\f;#')));
    if isempty(name)
      column_sign_id = findstr(line, keyword);
      name = strtok(line((column_sign_id+length(keyword)+1):end));
    end
    if isfield(a.Data, name)
      value = getfield(a.Data, name);
    else
      value = strtok(fliplr(reversed_line(1:(equal_sign_id-1))),sprintf(' \n\t\r\f;#'));
      if ~isempty(str2num(value)), value = str2num(value); end
    end
    
    if ~isempty(value) && ~isempty(name) && ischar(name)
      param = setfield(param, name, value);
    end
  end

