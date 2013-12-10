function out = ResLibCal_Compute(EXP)
% ResLibCal_Compute: update computation of resolution function
%
%   EXP: structure containing application configuration. When not given, extracts
%        it from the main window.
%
% Returns:
%   out: full output from ResLibCal, with resolution

% Calls: ResLibCal_fig2EXP, ResLibCal_EXP2RescalPar, ResLibCal_ComputeResMat

  persistent labels_c;

  if nargin == 0, EXP = ''; end
  
  out.Title  = 'ResLibCal configuration';
  
  if ~isstruct(EXP)
    % extracts configuration
    [EXP, fig] = ResLibCal_fig2EXP(get(0,'CurrentFigure'));
    out.handle = fig;
  else
    out.handle = [];
  end
  % check EXP structure. Perhaps it is a full ResLibCal structure
  if ~isstruct(EXP), return; end
  if isfield(EXP,'EXP')
    EXP = EXP.EXP;
  end
  
  out.EXP    = EXP; p = [];
  try
    [p, labels]= ResLibCal_EXP2RescalPar(out.EXP); % get ResCal vector and fields
  end
  if any(isnan(p))
    warning([ mfilename ': Computation can not be completed. Some parameters are NaN''s:']);
    disp(labels(isnan(p)))
  else
    try
      resolution = ResLibCal_ComputeResMat(out.EXP);
    catch
      warning([ mfilename ': Computation can not be completed.']);
      rethrow(lasterror)
      resolution = [];
    end
    out.resolution = resolution;
    if ~isempty(p)
      p = mat2cell(p(:),ones(1,length(p)));
      if isempty(labels_c), labels_c=strtok(labels); end
      out.ResCal = cell2struct(p(:),labels_c(:),1);
    end
  end
  
