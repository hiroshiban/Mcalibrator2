function [operator, comment] = launcher_read(filename)
% launcher_read: reads a .desktop (OpenDesktop/Linux) or .bat (Windows) launcher
%
%   [operator, comment] = launcher_read(filename)
%     reads a filename launcher, and retrieve the operator/command stored

% first test if this is a launcher
if nargin == 0, filename = []; end
if ~ischar(filename), return;  end

[p,f,e] = fileparts(filename);
% read launcher content and convert it to s structure
filename = fileread(filename);
w = warning('off','MATLAB:dispatcher:InexactCaseMatch');
filename = str2struct(filename);
warning(w);
  
if strcmp(e, '.desktop')
  [operator, comment] = launcher_read_opendesktop(filename);
elseif strcmp(e, '.bat')
  [operator, comment] = launcher_read_windowsbat(filename);
end

% ------------------------------------------------------------------------------
function [operator, comment] = launcher_read_opendesktop(launcher)
% Linux OpenDesktop/FreeDesktop
% <http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html>
% valid for Gnome, KDE, XFce, ...
% file ifit_<operator>.desktop
  % Exec=ifit %F <operator>
  % Name=<operator> (description)
  % Icon=<operator.png> or <iFit logo>
  % Comment=<operator> command | operator | model
  % Type=Application
  % GenericName=iFit Data Analysis
  % Categories=Education;Applications;Science;NumericalAnalysis;Physics
  % Terminal=true
  % Version=1.0
  
  operator = []; comment = [];
  % the Exec member should always start with ifit, and will contain %F
  if ~isfield(launcher, 'Exec'),     return; end
  if ~strncmp(launcher.Exec, 'ifit', 4), return; end
  % remove 'ifit' and the %F tokens
  operator = strrep(launcher.Exec, 'ifit','');
  operator = strtok(strrep(operator, '%F',''));
  if isfield(launcher,'Comment'), comment = launcher.Comment; end

function [operator, comment] = launcher_read_windowsbat(launcher)
% Windows BAT file
  % file ifit_<operator>.bat
  % @echo off
  % rem Comment=<operator> command | operator | model
  % rem Name=<operator>
  % ifit %~s* <operator>
  
