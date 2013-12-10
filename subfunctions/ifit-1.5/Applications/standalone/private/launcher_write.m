function [operator, comment] = launcher_write(filename, operator)
% launcher_write: writes a .desktop (OpenDesktop/Linux) or .bat (Windows) launcher
%
%   [operator, comment] = launcher_write(filename, operator)
%     writes a filename launcher, and feed-in the operator/command
%   filename: char
%   operator: char

% first test if this is a launcher
if nargin < 1, filename = []; end
if nargin < 2, operator = []; end
if ~ischar(filename), return;  end

% determine file type (from extension or platform)
if isdir(filename) && nargin > 1
  p = filename;
  f = operator;
  e = '';
else
  [p,f,e] = fileparts(filename);
  if isempty(p), p=pwd; end
end
if isempty(e)
  if ispc,       e='.bat';
  elseif isunix, e='.desktop';
  end
end

if isempty(operator), operator = f; end
launcher.operator = operator;

% get the help string from the command, then only the fisrt line
try
  if ismethod(iData, operator)
    h = help([ 'iData/' operator ]);
  elseif ismethod(iFunc, operator)
    h = help([ 'iFunc/' operator ]);
  else
    h = help(operator);
  end
  h = strtok(h, sprintf('\n\r\f'));
catch
  h = 'operator';
end

% create a launcher structure
if strcmp(operator, 'mcstas')
  % if operator is mcstas: require instrument to be given
  % but need to send parameters as well ? TODO
  launcher.type = 'instrument simulator';
else
  try
    obj = feval(operator);
    switch class(obj)
    case 'iData'
      % if operator is iData TODO
      launcher.type = 'data set';
    case 'iFunc'
      % if operator is iFunc, adds 'fits' after the model name to allow fiting to data set
      operator = [ operator ' fits' ];
      launcher.type = 'model';
    case 'struct'
      if isfield(obj, 'algorithm')
        % is an optimizer: we wish to minimize what is given, 
        % but need to get parameters ? TODO
        % input argument to the optimizer should probably be an iFunc
        % with no axis, but parameters, and a return value
        launcher.type = 'optimizer';
      end
    otherwise
      launcher.type = 'method';
    end
  catch
    if ismethod(iData, operator) && ismethod(iFunc, operator)
      launcher.type = 'Data/Model method';
    elseif ismethod(iData, operator)
      launcher.type = 'Data set method';
    elseif ismethod(iFunc, operator)
      launcher.type = 'Model method';
    elseif exist(operator)
      launcher.type = 'method';
    end
  end
end

% extract Comment from the operator 'help'
launcher.Exec     = operator;
launcher.Comment  = h;
launcher.filename = [ p filesep f e ];

if     strcmp(e, '.desktop')
  launcher_write_opendesktop(launcher);
elseif strcmp(e, '.bat')
  launcher_write_windowsbat(launcher);
end

% ------------------------------------------------------------------------------


function [operator, comment] = launcher_write_opendesktop(launcher)
% Linux OpenDesktop/FreeDesktop
% <http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html>
% valid for Gnome, KDE, XFce, ...
% file ifit_<operator>.desktop

  fid = fopen(launcher.filename, 'w+'); 
  if fid == -1
    warning( [ mfilename ': Could not open file ' launcher.filename] );
    return
  end
  fprintf(fid, '[Desktop Entry]\n');
  fprintf(fid, 'Version=1.0\n');
  fprintf(fid, 'Exec=ifit %%F %s\n', launcher.Exec);
  fprintf(fid, 'Name=%s %s\n',       launcher.operator, launcher.type);
  fprintf(fid, 'Icon=%s\n', [ '/usr/share/icons/ifit/' launcher.operator '.png' ]); % may not exist, then default to a noname icon
  fprintf(fid, 'Comment=%s\n',       launcher.Comment);
  fprintf(fid, 'Type=Application\n');
  fprintf(fid, 'GenericName=iFit Data Analysis\n');
  fprintf(fid, 'Terminal=true\n');
  fprintf(fid, 'Categories=Education;Applications;Science;NumericalAnalysis;Physics\n');
  fclose(fid);
  fileattrib(launcher.filename, '+x','a');

function [operator, comment] = launcher_write_windowsbat(launcher)
% Windows BAT file file ifit_<operator>.bat

  fid = fopen(launcher.filename, 'w+'); 
  if fid == -1
    warning( [ mfilename ': Could not open file ' launcher.filename] );
    return
  end
  fprintf(fid, 'rem Comment=%s %s\n',      launcher.operator, launcher.type);
  fprintf(fid, 'rem Name=%s\n',            launcher.operator);
  fprintf(fid, 'ifit %~s* %s\n',           launcher.Exec);
  fclose(fid);
  

