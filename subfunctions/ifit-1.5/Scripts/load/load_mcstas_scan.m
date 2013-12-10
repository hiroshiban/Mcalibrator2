function a=load_mcstas_scan(a0)
% function a=load_mcstas_scan(a0)
%
% Returns iData style datasets from a McStas scan output file
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

if ~isa(a0,'iData')
  a = load(iData,a0,'McStas scan');
  return
end

% handle input iData arrays
if numel(a0) > 1
  for index=1:numel(a0)
    a(index) = feval(mfilename, a0(index));
  end
  return
end

a=iData(a0);
if isempty(findstr(a,'McStas'))
  warning([ mfilename ': The loaded data set ' a.Tag ' from ' a.Source ' is not a McStas data format.' ]);
  return
end

% Define alias for the 'raw' datablock
setalias(a0,'Datablock',['this.' getalias(a0,'Signal')]);

% get the column labels
cnames=strread(a0.Data.Attributes.MetaData.variables,'%s','delimiter',' ');
cnames=cnames(3:end);

if ~isempty(findfield(a0, 'xlabel')) 
  xlabel = deblank(a0.Data.Attributes.MetaData.xlabel);
  xlabel(1:length('# xlabel: '))='';
else xlabel=''; end
if ~isempty(findfield(a0, 'ylabel')) 
  ylabel = deblank(a0.Data.Attributes.MetaData.ylabel);
  ylabel(1:length('# ylabel: '))='';
else ylabel=''; end
if ~isempty(findfield(a0, 'xvars')) 
  xvars = deblank(a0.Data.Attributes.MetaData.xvars);
  xvars(1:length('# xvars: '))='';
else xvars=''; end

if ~isempty(xvars)
  xvars_i = find(cellfun('isempty', strfind(cnames,xvars)) == 0);
  if ~isempty(xvars_i)
    if length(xvars_i) > 1
      cnames=cnames(xvars_i(end):end);
      xvars_i=xvars_i(1);
    end
    setalias(a0,'x',['this.' getalias(a0,'Signal') '(:,' num2str(xvars_i) ')' ],xvars); % create an alias for xvars
    setalias(a0,xvars,'x',xvars); % create an alias for xvars
    % locate xvars label and column
    xlabel=xvars;
  end

  % Define scanning variable
  setaxis(a0,1,'x');
end


param = load_mcstas_param(a0, 'Param');
a0.Data.Parameters = param;
setalias(a0, 'Parameters', 'Data.Parameters', 'Instrument parameters');

siz = size(a0.Signal);
siz = (siz(2)-1)/2;

a = [];
for j=1:siz
  b = copyobj(a0);
  ylabel=cnames(2*j);
  setalias(b,'Signal', ['this.' getalias(a0,'Signal') '(:,' num2str(2*j) ')'], ylabel);
  if ~isempty(findfield(a0, '_ERR')) 
    setalias(b,'Error',['this.' getalias(a0,'Signal') '(:,' num2str(1+2*j) ')']);
  end
  b.Title = [ char(ylabel) ': ' char(b.Title) ];
  b.Label = [ char(ylabel) '(' xvars ')' ];
  a = [a b];
end

% ------------------------------------------------------------------------------
% build-up a parameter structure which holds all parameters from the simulation
function param=load_mcstas_param(a, keyword)
  if nargin == 1, keyword='Param'; end
  param = [];

  par_list = findstr(a, keyword);
  % search strings of the form 'keyword' optional ':', name '=' value
  for index=1:length(par_list)
    line         = par_list{index};
    reversed_line= line(end:-1:1);
    equal_sign_id= find(reversed_line == '=');
    
    value        = strtok(fliplr(reversed_line(1:(equal_sign_id-1))),sprintf(' \n\t\r\f;#'));
    name         = fliplr(strtok(reversed_line((equal_sign_id+1):end),sprintf(' \n\t\r\f;#')));
    if ~isempty(num2str(value)), value = num2str(value); end
    if ~isempty(value) && ~isempty(name) && ischar(name)
      param = setfield(param, name, value);
    end
  end


