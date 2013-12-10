function pars=iFunc_private_guess(x, signal, parameter_names)
% pars=iFunc_private_guess(x, signal, parameter_names)
%      iFunc_private_guess({x y...}, signal, parameter_names)
%   guess private function to compute an estimate of parameters
%   given a signal and the model parameter names.
%   The following parameters can be set:
%     amplitude, intensity
%     peak width slope
%     peak center
%     constant background
%
% input:  x: single axis for 1D signal, or cell array of axes (cell or double vector)
%         signal: signal array (double)
%         parameter_names: names of model parameters (cellstr)
% output: pars: parameter values (double vector)
%
% Version: $Revision: 1035 $

  pars=[];
  if nargin == 2
    parameter_names = signal;
    signal          = x{end};
    x(end) = [];
  elseif nargin < 3, return; end
  if isempty(parameter_names), return; end

  pars            = zeros(size(parameter_names));
  parameter_names = lower(parameter_names);
  if iscell(x) && length(x) == 1, x=x{1}; end
  % handle signal dimension > 1
  if (~isvector(signal) && ~isempty(signal)) || (iscell(x) && length(x) > 1)
    % x must be a cell array with axes vector/matrices
    if ~iscell(x)
      whos x signal
      error([ mfilename ': x argument must be a cell array with the axes for the signal.']); end
    if ~isvector(signal) && ~isempty(signal) && length(x) ~= ndims(signal)
      whos x signal
      error([ mfilename ': x cell must contain all the axes for the signal.']); end
    if ~isempty(signal)
      for dim=1:sum(size(signal)>1)
        signal1d=signal;
        x1d     =x{dim};
        sz      =size(signal);
        for index=ndims(signal):-1:1
          if index~=dim, 
            if all(size(x1d)==size(signal1d)), x1d=sum(x1d, index)/sz(index); end
            signal1d=sum(signal1d, index)/sz(index); 
          end
        end
        
        signal1d=signal1d(:);     % signal along dimension (now 1D)
        zero_pars =find(~pars);   % will set those parameters which have not been set
        if isempty(x1d), x1d=1:length(signal1d); end
        pars(zero_pars) = iFunc_private_guess(x1d, signal1d, parameter_names(zero_pars));
      end
    else % case for empty signal: we use the axes to determine the parameters
      for dim=1:length(x)
        x1d     =x{dim};
        sz      =size(x1d);
        for index=ndims(x1d):-1:1
          if index~=dim, 
            if ~isvector(x{dim}), x1d=sum(x1d, index)/sz(index); end 
          end
        end
        zero_pars =find(~pars);  % will set those parameters which have not been set
        pars(zero_pars) = iFunc_private_guess(x1d, [], parameter_names(zero_pars));
        if isempty(x1d), pars(zero_pars) = pars(zero_pars)/dim; end
      end
    end
    return
  else
    if iscell(x) && length(x)==1, x=x{1}; end
  end
  if isempty(x), x=linspace(-5,6,50); end
  if ~isempty(signal) && isnumeric(signal)
    [sigma, position, amplitude, baseline] = iFunc_private_findpeaks(signal, 1, 0);
    % [sigma, position, amplitude, baseline] = peaks(iData(signal),1,0);
    % baseline = double(baseline);
    signal=signal(:);
    if isempty(sigma) || (length(sigma) == 1)
      sum_s = sum(signal); x1d=1:length(signal); x1d=x1d(:);
      % first moment (mean)
      f = sum(signal.*x1d)/sum_s; % mean value
      % second moment: sqrt(sum(x^2*s)/sum(s)-fmon_x*fmon_x);
      s = sqrt(sum(x1d.*x1d.*signal)/sum_s - f*f);
      position=f;
      sigma   =s/2;
      amplitude=max(signal)-min(signal);
      baseline =min(signal);
    end
  else
    % only the x axis is given: use default values from the axis extent
    
    sigma    = std(abs(x))/2;
    position = round(length(x)/2);
    amplitude= 1;
    baseline = 0.01;
  end

  % sort peaks by amplitude
  [dummy,sorti] = sort(amplitude);
  sorti=sorti(end:-1:1);                  % descending amplitude
  amplitude = amplitude(sorti);
  sigma     = sigma(sorti);
  position  = position(sorti);

  % assign parameter guessed values according to their names
  for index=1:length(amplitude)
    % search for names that match a pattern, and not set previously
    set_amplitude=0; set_centre=0; set_width=0; set_background=0;
    for index_p=1:length(parameter_names)
      if pars(index_p) ~= 0, continue; end % was set before, go on with further parameters
      % test parameter names
      if     ~isempty(strfind(parameter_names{index_p}, 'amplitude')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'intensity')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'height'))
        if ~set_amplitude, pars(index_p) = amplitude(index); set_amplitude=1; end
      elseif ~isempty(strfind(parameter_names{index_p}, 'width')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'tau')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'damping')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'slope')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'period'))
        if ~set_centre, pars(index_p) = sigma(index)*mean(diff(x))/2; set_centre=1; end
      elseif ~isempty(strfind(parameter_names{index_p}, 'centre')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'center')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'position')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'shift')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'offset'))
        if ~set_width && ~isempty(x), pars(index_p) = x(round(position(index))); set_width=1; end
      elseif ~isempty(strfind(parameter_names{index_p}, 'background')) ...
        |    ~isempty(strfind(parameter_names{index_p}, 'constant'))
        if ~set_background, 
          pars(index_p) = mean(baseline);
          set_background=1; 
        end
      end
    end
  end

end % iFunc_private_guess
