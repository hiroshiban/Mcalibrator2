function EXP = ResLibCal_Open(filename, EXP)
% EXP = ResLibCal_Open(filename): open an EXP/ResLib file and update main GUI
%
% Input:
% filename: file name (ResLibCal, ResCal or ILL TAS data file), 
%           or character string to evaluate (producing a structure or a vector)
%           or character string describing a structure
%           or structure with either EXP ResLib or ResCal fields
%
% Return:
%  EXP: configuration structure

% Calls: ResLibCal_RescalPar2EXP, ResLibCal_EXP2fig

  if nargin < 1, filename = ''; end
  if nargin < 2, EXP = []; end
  if isempty(filename)
    [filename, pathname] = uigetfile( ...
       {'*.m;*.ini',  'ResLibCal configuration M-file (*.m;*.ini)'; ...
        '*.cfg;*.par;*.res','ResCal5 configuration (*.par;*.cfg;*.res)' ; ...
        '*.*',  'All Files, including ILL TAS Data (*.*)'}, ...
        'Open configuration as ResLibCal, ResCal, ILL TAS Data, ...');
    if isempty(filename) || all(filename == 0), return; end
    filename = fullfile(pathname, filename);
  end
  if exist(filename,'file') % a file exists: read it
    % handle case of ResCal5 .par .cfg file (numerical vector)
    try
      content = load(filename); % usually produces a vector of Rescal parameters (42 or 27)
                                % can also be a .mat file for EXP/out
    catch
      % if not ResCal vector, read the file content (char)
      fid = fopen(filename, 'r');
      content = fread(fid, Inf, 'uint8=>char');
      content = content(:)';
      fclose(fid);
    end
  else
    content = filename;
  end
  if ischar(content) && ~isempty(content)  % content of a file, or string to evaluate
    try
      evalc(content);% this should make an 'EXP' or 'config' variable
      if ~isempty(config)
        EXP = config; % replace EXP full config (override any previous setting)
        content = ''; % success unactivates further interpretation of input
      end
    end
  end

  if ischar(content) || isstruct(content) || isnumeric(content) % converted from a string or read from a file
    % read content as a structure, ResCal par/cfg, ...
    if isfield(EXP,'EXP'), EXP=EXP.EXP; end
    EXP = ResLibCal_RescalPar2EXP(content, EXP);
    % overload EXP with ResCal structure if EXP is incomplete and ResCal is
    % there
    if isfield(EXP,'ResCal') && ~isfield(EXP, 'mono') && ~isfield(EXP, 'sample') && ~isfield(EXP, 'ana')
      EXP = ResLibCal_RescalPar2EXP(EXP.ResCal, EXP);
    end
  end

  % evaluate it to get 'EXP'
  if isstruct(EXP)
    % send it to the figure
    try
      ResLibCal_EXP2fig(EXP); % open figure if not yet done
      disp([ '% Loaded ResLibCal configuration from ' filename ]);
    catch
      warning([ '% Could not load ResLibCal configuration ' filename ]);
      rethrow(lasterror)
    end
  end
% end ResLibCal_Open
