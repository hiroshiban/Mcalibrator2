function filename = ResLibCal_Saveas(filename, EXP)
% ResLibCal_Saveas(filename): save the GUI configuration to an EXP/ResLib file
%
% Return:
%  filename: name of file written

% Calls: ResLibCal_Compute, class2str

  if nargin < 1, filename =''; end
  if nargin < 2, EXP=''; end

  if isempty(filename)
    [filename, pathname] = uiputfile( ...
         {'*.m',  'M-files (*.m)'; ...
          '*.ini','ResLibCal configuration (*.ini)' ; ...
          '*.cfg;*.par;*.res','ResCal5 configuration (*.par;*.cfg;*.res)' ; ...
          '*.*',  'All Files (*.*)'}, ...
          'Save ResLibCal configuration as ...');
    if isempty(filename) || all(filename == 0), return; end
    filename = fullfile(pathname, filename);
  end

  if isempty(EXP)
    EXP = ResLibCal_Compute; % collect current settings and compute
  end
  if ~isempty(EXP)
    % do we reduce output to ResCal only ? based on extension match
    [p,f,e] = fileparts(filename);
    if any(strcmp(e,{'.res','.cfg','.par'})) && isfield(EXP,'ResCal')
      str = class2str(' ', EXP.ResCal, 'no comment');
      str = strrep(str, ';', ''); % remove trailing ';'
    else
      str = [ '% ResLibCal configuration script file ' sprintf('\n') ...
            '%' sprintf('\n') ...
            '% Matlab ' version ' m-file ' filename sprintf('\n') ...
            '% generated automatically on ' datestr(now) ' with ' mfilename sprintf('\n') ...
            '% The Resolution function is indicated as the "resolution.RMS" field ' sprintf('\n') ...
            '% (in lattice rlu), "resolution.RM" is in [Angs-1] in [QxQyQzE].' sprintf('\n') ...
            '% Modify "config" rather than "config.ResCal".' sprintf('\n') ...
            class2str('config', EXP) ];
    end
    
    [fid, message]=fopen(filename,'w+');
    if fid == -1
      warning(['Error opening file ' filename ' to save ResLibCal configuration.' ]);
      filename = [];
    else
      fprintf(fid, '%s', str);
      fclose(fid);
      disp([ '% Saved ResLibCal configuration into ' filename ]);
    end
  end
% end ResLibCal_Saveas
