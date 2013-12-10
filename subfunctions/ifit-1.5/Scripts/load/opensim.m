function out = opensim(filename)
%OPENSIM Open a McStas SIM file, display it
%        and set the 'ans' variable to an iData object with its content

if ~isa(filename,'iData')
  out = iData(iLoad(filename,'SIM'));
else
  out = filename;
end
clear filename;

if numel(out) > 1
  % handle input iData arrays
  for index=1:numel(out)
    out(index) = feval(mfilename, out(index));
  end
end

if ~isempty(findstr(out,'McStas'))
  % this is a McStas file
  
  % Find filename fields in sim struct:
  filenames = findstr(out,'filename');
  if ~iscellstr(filenames), filenames = { filenames }; end
  dirname   = fileparts(out.Source);
  
  a=[];
  if length(filenames(:)) > 0
    % This is a McStas 'overview' plot
    for j=1:length(filenames(:))
      filename = filenames{j};
      filename(~isstrprop(filename,'print')) = '';
      filename(1:length('filename: '))='';
      filename=strtrim(filename);
      filename(findstr(' ',filename):length(filename))='';
      if isempty(filename), continue; end
      filename = fullfile(dirname,filename);
      a = [ a iData(filename) ];
    end
  else
    % This is a .sim from a scan
    filename = 'mcstas.dat';
    filename = fullfile(dirname,filename);
    a = iData(filename);
  end
  out = a;
  clear a;
end

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end

