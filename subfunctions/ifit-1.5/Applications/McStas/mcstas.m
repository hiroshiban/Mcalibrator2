function [pars,fval,exitflag,output] = mcstas(instrument, parameters, options)
% [OPTIMUM,MONITORS,EXITFLAG,OUTPUT] = mcstas(INSTRUMENT, PARAMETERS, OPTIONS) : run and optimize a McStas/McXtrace simulation
%
% A wrapper to the <a href="http://www.mcstas.org">McStas</a> package to either execute a simulation, or optimize a
%   set of parameters. When given as strings, the PARAMETERS and OPTIONS are 
%   searched for name=value pairs, separated by the ';' character.
%
% The default execution mode is 'simulate', which also includes scanning capability.
% Scans of parameters with vectors and cell strings are possible. Multiple
% dimension scans are also possible
%   mcstas('instrument','parameter1=1; parameter2=[2 3 4]','dir=scan_test')
%   mcstas('instrument',struct('p1',1,'p2',[2 3 4],'p3',{'Al.laz','Cu.laz'}))
% The resulting integrated monitors are returned in OPTIMUM, MONITORS holds the
%   monitors content as iData objects. The EXITFLAG is set to 0, and OUTPUT
%   holds the options used. If the options.dir is not set, a temporary directory
%   is created for the simulations, then deleted. 
% To select neutron (McStas) or X-rays (McXtrace) flavour, set the options.particle
%   to 'n' or 'x'.
%
% To select the optimization mode, set the options.mode='optimize' or any other
%     optimization configuration parameter (TolFun, TolX, ...). 
%     Only numerical parameters can be optimized, others are kept fixed. The search
%     is restricted to a bounded range when parameters are given as vectors [min,max].
%     As McStas simulations are noisy, it is recommended to constraint all parameters. 
%     The criteria used for the search can be given in the options.monitors as a
%     string or cell of strings. The sum of the monitor content is then used. 
%     The default optimization maximizes the criteria.
%     Each entry should begin by the monitor filename possibly followed by any 
%     expression using 'this' to refer to the monitor content:
%       options.monitors='Monitor' will match all files starting by 'Monitor'
%       options.monitors={'Monitor1','Monitor2'} uses two monitor integrals
%       options.monitors='Monitor1/std(this)^4' divides the monitor by its half width^4
%       options.monitors='Monitor1; this = this/std(this)^4' same as above
%     The OuputFcn is set to 'fminplot' as default. Define options.OutputFcn=''
%     to override this choice.
%   mcstas('instrument','parameter1=[0 1]; parameter2=[2 4]','dir=optim_test; mode=optimize')
% The best optimized parameter set is returned in OPTIMUM, MONITORS holds the
%   optimized monitors content as iData objects. The EXITFLAG is the return value
%   from the optimizer, and OUTPUT holds additional simulation and optimization stuff.
%
% The Trace 3D view mode is executed when using mode=display, but does not show neutron
%     trajectories.
%   mcstas('instrument','parameter1=Al.laz; parameter2=3','mode=display')
%
% The syntax:
%   mcstas(instrument,'--compile')     assemble and compile the instrument
%   mcstas(instrument,'--compile mpi') same with MPI support
%   mcstas(instrument,'--info')        returns instrument information
%
% input:  INSTRUMENT: name of the instrument description to run (string)
%           when the instrument is not found, it is searched in the McStas 
%           examples, and copied locally.
%         PARAMETERS: a structure that gives instrument parameter names and 
%             values (structure)
%           parameters.name = scalar (optimization, simulation and display)
%             define a single value      when options.mode='simulation' and 'display'
%             define the starting value  when options.mode='optimization'
%           parameters.name = vector and cell array (simulation)
%             define a scanning range for a series of simulations, when 
%             options.mode='simulation' multi-dimensional scans (that is more 
%             than one parameter given vector) are possible.
%           parameters.name = vector (optimize)
%             the vector can be 3 elements to define [min start max]. 
%             the vector can be 2 elements to define [min max]. 
%             the vector can be 4+ elements to define [min ... max]. 
%             For 2 and 4+ vectors, the parameter starting value is the mean of the vector.
%           parameters.name = string (simulation, optimization and display)
%             defines a fixed parameter, that can not be optimized.
%         OPTIONS: a structure or string that indicates what to do (structure)
%           options.dir:    directory where to store results (string)
%           options.overwrite: 0 or 1 to either keep or force output
%             directory to be overwritten (boolean)
%           options.ncount: number of neutron events per iteration, e.g. 1e5 (double)
%           options.mpi:    number of processors/cores to use with MPI on localhost (integer) 
%           options.seed:   random number seed to use for each iteration (double)
%           options.gravitation: 0 or 1 to set gravitation handling in neutron propagation (boolean)
%           options.compile: 0 or 1 to force re-compilation of the instrument (boolean)
%           options.mode:   'simulate' (default), 'optimize' or 'display' (string)
%           options.type:   'minimize' or 'maximize', which is the default (string)
%           options.particle: 'n' (default) or 'x' depending if you use McStas or McXtrace (string)
%           options.monitors:  cell string of monitor names, or empty for all (cellstr)
%             the monitor names can contain expressions made of the monitor name 
%             followed by any expression using 'this' to refer to the monitor content
%             such as in 'Monitor1/std(this,1)' which divides the Signal by its X peak width.
%           options.help:   set it to 'yes' or 1 to get help on the instrument and exit
%           options.info:   set it to 'yes' or 1 to get information on the instrument and exit
%           options.optimizer: function name of the optimizer to use (string or function handle)
%           options.OutputFcn: monitors the scan/optimization process on a plot (string)
%         as well as other optimizer options such as
%           options.TolFun ='0.1%'   stop when criteria changes are smaller that 0.1%
%           options.Display='final'
%
% output:  OPTIMUM is the parameter set that maximizes the instrument output, or
%            the integral monitor values for the simulation (as iData object)
%          MONITORS contains the instrument output as iData objects. Each object has an
%            additional Parameter member alias which holds the instrument parameters.
%          EXITFLAG return state of the optimizer, or 0.
%          OUTPUT additional information returned as a structure.
%
% example: Optimize templateDIFF instrument parameter RV
%   [p,f]=mcstas('templateDIFF', 'RV=[0.5 1 1.5]', struct('TolFun','0.1%','monitors','Banana'));
% Display result
%   subplot(f); disp(f.Parameters)
% Perform a scan of instrument parameter RV
%   [monitors_integral,scan]=mcstas('templateDIFF' ,struct('RV',[0.5 1 1.5]))
%   plot(monitors_integral)
% Display instrument geometry
%   fig = mcstas('templateDIFF','RV=0','mode=display');
% Type <a href="matlab:doc(iData,'McStas')">doc(iData,'McStas')</a> to access the iFit/McStas Documentation.
%
% Version: $Revision: 1166 $
% See also: fminsearch, fminpso, optimset, http://www.mcstas.org

% inline: mcstas_criteria

  if nargin < 1
    error([ 'syntax is: ' mfilename '(instrument, parameters, {options})' ] );
  end

  if ~exist('iData')
    error([ mfilename ' requires iFit/iData. Get it at <ifit.mccode.org>. Install source code with addpath(genpath(''/path/to/iFit'')) or use standalone version.' ] );
  end
  
% PARSE INPUT ARGUMENTS ========================================================

  pars=[]; fval= []; exitflag=-1; output=[];
  
  if nargin > 2 && ischar(options)
    options= str2struct(options);
  end
  
  % check if the instrument exists, else attempt to find it
  [p,f,e] = fileparts(instrument);
  if isempty(e)
    instrument = [ instrument '.instr' ];
  end
  if ~isempty(instrument)
    index = dir(instrument);
  else return;
  end
  
  % check for instrument in McStas/McXtrace libraries
  search_dir = { getenv('MCSTAS'), getenv('MCXTRACE'), ...
    '/usr/local/lib/mc*', 'C:\mc*'};
  if isempty(index)
    % search the instrument recursively in all existing directories in this list
    index = getAllFiles(search_dir, instrument);
    if ~isempty(index)
      disp([ mfilename ': Copying instrument ' index ' in ' pwd ] );
      copyfile(index, instrument);
    end
  end
  
  if isempty(index)
    error([ mfilename ': ERROR: Can not find instrument ' instrument ]);
  end
  
  options.instrument     = instrument;
  % define simulation or optimization mode (if not set before)
  if ~isfield(options,'mode')
    if isfield(options, 'optimizer')  || isfield(options,'TolFun') || ...
       isfield(options,'TolX')        || isfield(options,'type')   || ...
       isfield(options,'MaxFunEvals') || isfield(options,'MaxIter')
      options.mode      = 'optimize'; 
    else
      options.mode      = 'simulate';
    end
  end
  
  if ~isfield(options,'particle')
    options.particle = 'n';
  end
  
  if ~isfield(options,'dir')
    options.dir = tempname;
    use_temp    = 1; 
  else 
    use_temp    = 0; 
  end
  if ~isfield(options,'ncount')
    if strcmpi(options.mode, 'optimize')
      options.ncount    = 1e5;
      if ~isfield(options,'TolFun')
        options.TolFun = '0.1%';
      end
    else
      options.ncount    = 1e6;
    end
  end
  % force compile before going further ?
  if  isfield(options,'compile') & (options.compile | strcmp(options.compile,'yes'))
    ncount         = options.ncount;
    options.ncount = 0;
    mcstas_criteria([], options);
    options        = rmfield(options,'compile');
    options.ncount = ncount;
  end
  if isfield(options,'info') && options.info
    options.mode = 'info';
  end
  
  % parse parameter values for mcstas_criteria
  % syntax: mcstas(instr, 'compile mpi') -> only compile
  if ischar(parameters) 
    if ~isempty(strfind(parameters,'--compile')) || ~isempty(strfind(parameters,'-c'))
      options.compile = 1;
      if ischar(parameters) && (~isempty(strfind(parameters,' mpi')) || ~isempty(strfind(parameters,'mpi ')))
        options.mpi=2;
        parameters      = [];
      end
    end
    if ~isempty(strfind(parameters,'--info')) || ~isempty(strfind(parameters,'-i'))
      options.mode = 'info';
      parameters      = [];
    end
  end
  if nargin < 1, parameters = []; end
  if ischar(parameters)
    parameters = str2struct(parameters);
  end
  if ~isempty(parameters) && isstruct(parameters)
    parameter_names = fieldnames(parameters);
  else
    parameter_names = {};
  end
  fixed_names     = {};
  variable_names  = {};
  fixed_pars      = {};
  scan_size       = [];
  if strcmpi(options.mode, 'optimize')
    variable_pars   = [];
  else
    variable_pars   = {};
  end
  constraints = []; % for optimization min/max
  for index=1:length(parameter_names)
    value = getfield(parameters, parameter_names{index});
    value = value(:);
    if ischar(value) % fixed values for both simulation and optimization
      fixed_pars{end+1} = value(:)';
      fixed_names{end+1}= parameter_names{index};
    elseif isvector(value) % this is a vector: numeric or cell
      if strcmpi(options.mode, 'optimize')
        if ~isnumeric(value)
          error([ mfilename ': Parameter ' parameter_names{index} ' of type ' class(value) ' is not supported.' ...
            sprintf('\n') 'Optimization only supports numerics as input.']);
        end
        % optimize parameter=numerical vector 
        if length(value) > 1
          % the vector in optimization mode allows definition of constraints
          if isempty(constraints) % define constraints to NaN up to now
            constraints.min = NaN*ones(size(variable_pars));
            constraints.max = constraints.min;
          end
          constraints.min(end+1) = min(value); % add the new constraints for this parameter.
          constraints.max(end+1) = max(value);
          if length(value) == 3
            value = value(2); % syntax: parameter=[ min start max ]
          end
          variable_pars(end+1) = mean(value(:));
        else
          if ~isempty(constraints)
            constraints.min(end+1) = NaN; % if use constraints elsewhere,
            constraints.max(end+1) = NaN; % fill in no-constraints for this parameter
          end
          variable_pars(end+1) = value;
        end
      else % simulate mode: we just store the vector, that will be scanned through
        scan_size(end+1)     = length(value);
        variable_pars{end+1} = value;
      end
      variable_names{end+1}= parameter_names{index};
    else % not a vector (probably a char)
      error([ mfilename ': Parameter ' parameter_names{index} ' of type ' class(value) ' is not supported.' ...
        sprintf('\n') 'Prefer numerical or cell vectors.']);
    end
  end % for index
  
  % optimizer configuration and end-user choices
  options.variable_names = variable_names;
  options.variable_pars  = variable_pars;
  options.fixed_names    = fixed_names;
  options.fixed_pars     = fixed_pars;
  options.scan_size      = scan_size;
  pars                   = variable_pars;
  
% Launch optimize and simulate mode ============================================

  if isfield(options,'monitors')
    options.monitors = cellstr(options.monitors);
  end
  
  warn.structs = [ ...
    warning('off','iData:setaxis') warning('off','iData:getaxis') ...
    warning('off','iData:get')     warning('off','iData:subsref') ];

  if strcmpi(options.mode,'optimize') % ================================ OPTIMIZE
    % optimize simulation parameters
    if ~isfield(options,'type'),      options.type      = 'maximize'; end
    if ~isfield(options,'optimizer'), options.optimizer = @fminpso; end
    options.overwrite = 1;
    
    % specific optimizer configuration
    optimizer_options = feval(options.optimizer,'defaults');
    optimizer_options.OutputFcn = 'fminplot';
    optimizer_options.TolFun    = '1%';
    field_names=fieldnames(optimizer_options);
    for index=1:length(fieldnames(optimizer_options))
      if ~isfield(options, field_names{index})
        options = setfield(options, field_names{index}, getfield(optimizer_options, field_names{index}));
      end
    end

    % launch optimizer with or without constraints
    if isempty(constraints)
      [pars,fval,exitflag,output] = feval(options.optimizer, ...
        @(pars) mcstas_criteria(pars, options), pars, options);
    else
      [pars,fval,exitflag,output] = feval(options.optimizer, ...
        @(pars) mcstas_criteria(pars, options), pars, options, constraints);
    end
    output.parameters=parameters;
    options.mode = 'simulate'; % evaluate best solution, when optimization is over
    if nargout > 1
      fprintf(1,'Evaluating final solution...\n');
      [dummy,fval] = mcstas_criteria(pars, options);
      output.command=get(fval(1), 'Execute');
    end
    % re-create a structure of parameters
    pars_struct = [];
    for index=1:length(pars)
      pars_struct.(variable_names{index}) = pars(index);
    end
    pars = pars_struct;
  elseif strcmpi(options.mode,'simulate') % ============== SINGLE simulation/scan

    [p, fval] = mcstas_criteria(pars, options);   % may fail at execution
    
    fval = squeeze(fval);
    p    = squeeze(p);
    if iscell(fval) && ~isempty(fval)
      % before converting to a single iData array, we check that all
      % simulations returned the same number of monitors
      for index=1:numel(fval)
          if isempty(fval{index}), fval{index}=iData; end
      end
      siz = cellfun('prodofsize',fval);
      if all(siz == siz(1))
        fval=iData(fval);
      end
    end
    if isempty(fval)
      pars=[]; fval=[];
    elseif nargout < 2
      pars     = fval;
    else
      % create the iData object of the integral(monitors)
      a = iData(p);
      try
        t = fval(1); isscan = t.Data.Scan;
        t = ' Scan of'; isscan = 1;
      catch
        t = ''; isscan = 0;
      end
      for index=1:length(options.variable_names)
        setalias(a, options.variable_names{index}, options.variable_pars{index});
        if isscan==1 && isnumeric(options.variable_pars{index}) && length(options.variable_pars{index}) > 1
          setaxis(a, index, options.variable_names{index});
        end
        t = [ t ' ' options.variable_names{index} ];
      end
      setalias(a, 'Criteria', 1:size(a, ndims(a)), 'Monitor index');
      if isscan==1
        setaxis(a, length(options.variable_names)+1, 'Criteria');
      end
      % add other metadata to the integral object
      % set(a, 'Data.Parameters', parameters);
      set(a, 'Data.Criteria', p);
      if iscell(fval)
      set(a, 'Data.Execute', get(fval{1},'Execute'));
      else
      set(a, 'Data.Execute', get(fval(1),'Execute'));
      end
      set(a, 'Data.Options', options);
      setalias(a, 'Parameters', 'Data.Parameters','Instrument parameters');
      setalias(a, 'Execute', 'Data.Execute','Command line used for Mcstas execution');
      setalias(a, 'Options', 'Data.Options','Options used for Mcstas execution');
      a.Title = [ instrument ':' t ];
      a.Label = instrument;
      pars = a;
    end 
    exitflag = 0;
    output   = options;
  elseif any(strcmpi(options.mode,{'display','trace','info'}))
    [pars, fval] = mcstas_criteria(pars, options);
  end % else single simulation
  
  warning(warn.structs);

  if use_temp==1
    % clean up last iteration result when stored into a temporary location
    success = rmdir(options.dir,'s');
  end

end
% end of mcstas function

% ------------------------------------------------------------------------------

function [status, result]=system_wait(cmd, options)
% inline function to execute command and wait for its completion (under Windows)
% dots are displayed under Windows after every minute waiting.
  [status, result]=system(cmd);
  disp(result);
  if status ~= 0, return; end
  % need to wait for simulation to complete, except for Trace mode
  if ~any(strcmpi(options.mode,{'display','trace','info'}))
    if ispc % wait for completion by monitoring the number of elements in the result directory
            % this does not work when using temporary intermediate save with Progress_bar(flag_save=1)
      t=tic; t0=t; first=1;
      a=dir(options.dir);
      while length(a) <= 3 % only 'mcstas.sim', '.', '..' when simulation is not completed yet
        if toc(t) > 60
          if first==1 % display initial waiting message when computation lasts more than a minute
            fprintf(1, 'mcstas: Waiting for completion of %s simulation (dots=minutes).\n', options.instrument);
          end
          fprintf(1,'.');
          t=tic; first=first+1;
          if first>74 % go to next line when more than 75 dots in a row...
            first=2;
            fprintf(1,'\n');
          end
        end
        a=dir(options.dir); % update directory content list
      end
      fprintf(1,' DONE [%10.2g min]\n', toc(t0)/60);
    end
    % wait for directory to be 'stable' (not being written)
    this_sum=0;
    while 1
      a=dir(options.dir);
      new_sum=0;
      for index=1:length(a)
          new_sum = new_sum+a(index).datenum;
      end
      if this_sum == new_sum, break; end
      this_sum = new_sum;
      pause(1);
    end
  end
end % system_wait

% ------------------------------------------------------------------------------

function [criteria, sim, ind] = mcstas_criteria(pars, options, criteria, sim, ind)
% inline function to compute a single simulation, or a vector of simulations (recursive calls)

  if options.particle == 'x'
    prefix = 'mx';
  else
    prefix = 'mc';
  end
  
  % launch simulation with mcrun/mxrun or mcdisplay/mxdisplay
  if any(strcmpi(options.mode,{'optimize','simulate','info'}))
    cmd = [ prefix 'run ' options.instrument ];
  elseif any(strcmpi(options.mode,{'display','trace'}))
    cmd = [ prefix 'display -pMatlab --save ' options.instrument ];
    options.ncount=0;
  end
  
  % usual McStas/mcrun options
  if isfield(options,'compile') & (options.compile | strcmp(options.compile,'yes'))
    cmd = [ cmd ' --force-compile' ];
    if isempty(pars)
      options.ncount=0;
      options.dir   ='';
    end
  end
  if isfield(options,'ncount') && ~isempty(options.ncount)
    cmd = [ cmd ' --ncount=' num2str(options.ncount) ];
  end
  if isfield(options,'dir') && ~isempty(options.dir)
    % clean up previous simulation result
    if isfield(options, 'overwrite') && options.overwrite
      index = rmdir(options.dir, 's');
    end
    if ~isempty(dir(options.dir))
      error([ mfilename ': ERROR: The target directory "' options.dir '" already exists. Use an other target, delete it prior to the execution, or use options.overwrite=1.' ]);
    end
    cmd = [ cmd ' --dir=' options.dir ];
  end
  if isfield(options,'gravitation') && (options.gravitation || strcmp(options.gravitation,'yes'))
    cmd = [ cmd ' --gravitation' ];
  end
  if isfield(options,'mpi') && ~any(strcmpi(options.mode,{'display','trace','info','help'}))
    if isempty(options.mpi)
      cmd = [ cmd ' --mpi' ];
    elseif options.mpi > 1
      cmd = [ cmd ' --mpi=' num2str(options.mpi) ];
    end
  end
  if strcmp(options.mode, 'info')
    cmd = [ cmd ' --info' ];
  end
  if isfield(options,'help')
    cmd = [ cmd ' --help' ];
  end
  if isfield(options,'seed') && ~isempty(options.seed)
    cmd = [ cmd ' --seed=' num2str(options.seed) ];
  end
  dir_orig = options.dir;
  % handle single simulation and vectorial scans ===============================
  % determine parameter list, those which are fixed and the variable ones
  if isfield(options,'variable_names')
    if nargin < 3, 
      ind = cell(1,length(options.variable_names)); ind{1}=1; 
      if ~exist('criteria')
        criteria = [];
        sim      = {};
      end
    end

    for index=1:length(options.variable_names)  % loop on variable parameters
      if isnumeric(pars) % all numerics
        cmd = [ cmd ' ' options.variable_names{index} '=' num2str(pars(index)) ];
      else % some are cells and chars
        % scan mode, with vector parameters
        this = pars{index};
        if isnumeric(this) && length(this) == 1
          cmd = [ cmd ' ' options.variable_names{index} '=' num2str(this) ];
        elseif ischar(this)
          cmd = [ cmd ' ' options.variable_names{index} '=' this ];
        elseif isvector(this) % parameter is a vector of numerics/scans
          if isempty(dir(dir_orig))
            mkdir(dir_orig)
          end
          for index_pars=1:length(this) % scan the vector parameter elements
            ind{index} = index_pars; % coordinates of this scan step in the parameter space indices
            options.dir = [ dir_orig filesep num2str(prod([ ind{:} ]) -1) ];
            if isnumeric(this)
              pars{index} = this(index_pars);
            elseif iscell(this)
              pars{index} = this{index_pars};
            end
            % recursive call to handle all scanned parameters
            [this_criteria, this_sim, ind] = mcstas_criteria(pars, options, criteria, sim, ind);
            if ~iscell(this_sim)   % single simulation
              if isempty(criteria) % initialize arrays to the right dimension
                criteria = zeros([ options.scan_size length(this_criteria) ]); % array of 0
                sim      = cell( size(criteria) );                             % empty cell
              end

              % add single simulation to scan arrays
              % store into the last dimensionality (which holds monitors and integrated values)
              if ~isempty(this_sim)
                for index_mon=1:length(this_criteria)
                  if isempty(ind), this_ind = { index_mon };
                  else this_ind = { ind{:} index_mon }; end
                  this_ind(cellfun('isempty',this_ind))={1};
                  try
                  sim{      sub2ind(size(sim), this_ind{:}) } = this_sim(index_mon);
                  criteria( sub2ind(size(sim), this_ind{:}) ) = this_criteria(index_mon);
                  catch
                  sim{      this_ind{:} } = this_sim(index_mon);
                  criteria( this_ind{:})  = this_criteria(index_mon);
                  end
                end
              end
            else
              criteria = this_criteria;
              sim      = this_sim;
            end
            % optionally plot the criteria during the scan...
            this_criteria = squeeze(criteria);
            if length(size(this_criteria)) <= 2
              if (isfield(options, 'OutputFcn') && ~isempty(options.OutputFcn)) ...
              || (isfield(options, 'Display') && strcmp(options.Display, 'iter'))
                % is this window already opened ?
                h = findall(0, 'Tag', 'McStasScan');
                if isempty(h) % create it
                  h = figure('Tag','McStasScan', 'Unit','pixels');
                  tmp = get(h, 'Position'); tmp(3:4) = [500 400];
                  set(h, 'Position', tmp);
                end
                % raise existing figure (or keep it hidden) and add parameters on top
                if gcf ~= h, set(0, 'CurrentFigure', h); end
                if isvector(this_criteria)
                  plot(this, this_criteria)
                  xlabel([ 'Scan step ' options.variable_names{index} ]); ylabel('Integral');
                else
                  surf(this_criteria);
                  ylabel('Scan step'); xlabel('Monitors'); zlabel('Integral');
                end
                t=title([ options.instrument ': ' options.variable_names{index} '=' num2str(pars{index}) ]); 
                set(t,'interpreter','none');
                drawnow
              end
            end
          end % for index_pars
          if nargout < 2
            criteria = sim;
          end
          return  % return from scan
        end % elseif isvector(this): parameter value given as vector 
      end
    end % for index
  end
  % non scanned parameters (chars, fixed)
  if isfield(options,'fixed_names')
    for index=1:length(options.fixed_names)
      cmd = [ cmd ' ' options.fixed_names{index} '=' options.fixed_pars{index} ];
    end
  end
  
  % Execute simulation =========================================================
  disp([ mfilename ': ' options.mode ': ' cmd ]);
  
  % remove previous 3d view if any
  if any(strcmpi(options.mode,{'display','trace'}))
    % should identify the figure file name
    [p,f,e] = fileparts(options.instrument);
    fig = [ f '.fig' ]; % the instrument view has 'fig' extension
    if ~isempty(p), fig=fullfile(p, fig); end
    delete(fig);
  end
  
  % EXECUTE here: simulate, optimize and display modes
  [status, result] = system_wait(cmd, options);
  
  if any(strcmpi(options.mode,{'display','trace'})) && status == 0
    % wait for figure to be ready...
    t=clock;
    disp([ mfilename ': Waiting for the instrument ' options.instrument ' view to be created as ' fig ])
    while isempty(dir(fig)) && etime(clock, t) < 60
      fprintf(1, '.')
      pause(5);
    end
    fprintf(1, '\n');
    if ~isempty(dir(fig))
      fig = openfig(fig);
      cmdshort=cmd; if length(cmd) > 70, cmdshort=[ cmd(1:60) '... ' cmd((end-8):end) ]; end 
      h = uicontrol('String','Info','Callback',[ 'helpdlg(''' cmd ''',''Instrument parameters'');' ],'ToolTip', cmd);
      view(3); set(fig, 'ToolBar','figure','menubar','figure');
      criteria = fig;
    else
      criteria=[];
    end
  elseif strcmpi(options.mode,'info')
    criteria = str2struct(result);
    return
  end
  
  if nargout ==0, return; end
  if status
    error([ mfilename ': ERROR: Failed to execute ' cmd ]);
  end
  
  if isfield(options,'ncount') && options.ncount == 0
    return
  end
  directory = options.dir;

  % import McStas simulation result
  sim = [];
%  try
    % select monitors from their file names and apply expression (if any)
    if isfield(options,'monitors')
      for index=1:length(options.monitors)
        [name, R] = strtok(options.monitors{index},' ,;/*+-(){}:%$.');
        sim = [ sim iData(fullfile(directory,[ '*' name '*' ])) ];
        if isempty(sim)
            error([ mfilename ': ERROR: no ' name ' monitor when launching ' cmd ]);
        end
        setalias(sim, 'CriteriaExpression', R);
      end
    end
    
    if isempty(sim)
      % if designated monitor file name import fails, import all simulation content
      if ~isempty(dir([ directory filesep 'mcstas.sim' ]))
        directory = [ directory filesep 'mcstas.sim' ];
      end
      sim = iData(directory); % a vector of monitors (iData objects)
      
      % filter all simulation monitor
      if isfield(options,'monitors') & numel(sim) > 1
        % restrict monitors from simulation by matching patterns
        use_monitors = zeros(size(sim));
        for index=1:length(options.monitors)
          % find monitors that match a search token
          this = cellfun('isempty', findstr(sim, strtok(options.monitors{index},' ,;/*+-(){}:%$.')));
          this = find(this == 0); % find those that are not empty (match token)
          use_monitors(this) = 1;
        end
        if any(use_monitors)
          sim = sim(find(use_monitors));
        end
      end
    end
    
%  catch
%    criteria=0; sim=[]; ind=[];
%    return
%  end

  % option to plot the monitors
  if (isfield(options, 'OutputFcn') && ~isempty(options.OutputFcn)) ...
  || (isfield(options, 'Display') && strcmp(options.Display, 'iter'))
    % is this window already opened ?
    h = findall(0, 'Tag', 'McStasMonitors');
    if isempty(h) % create it
      h = figure('Tag','McStasMonitors', 'Unit','pixels');
      tmp = get(h, 'Position'); tmp(3:4) = [500 400];
      set(h, 'Position', tmp);
    end

    % raise existing figure (or keep it hidden) and add parameters on top
    if gcf ~= h, set(0, 'CurrentFigure', h); end
    hold off
    if length(sim) <= 4
      subplot(sim,'view2 axis tight');
    else
      subplot(sim,'view2 axis tight hide_axes'); % use compact layout for many monitors
    end
    % add quick overview of shown monitors
    sim_abstract = 'Monitors:';
    for index=1:numel(sim)
      sim_abstract=[ sim_abstract sprintf('\n') '* ' get( sim(index),'Label') ...
        sprintf(' [I I_err N]=[%g %g %g] %s', get(sim(index),'values'), get(sim(index),'statistics')) ] ;
    end
    ud.Parameters = get(sim(1),'Parameters');
    ud.Execute=cmd;
    ud.pars   =pars;
    ud.Options=options;
    xl=xlim; yl=ylim;
    f = fieldnames(ud.Parameters);
    c = struct2cell(ud.Parameters);
    max_fields=10; % at most as many parameters displayed, else this is too much to read
    if length(f) > max_fields, 
      dots=sprintf(' ... [%i other parameters]', length(f)-max_fields);
      f=f(1:max_fields); c=c(1:max_fields); 
    else dots = ''; end
    cmdshort=cmd; if length(cmd) > 70, cmdshort=[ cmd(1:60) '... ' cmd((end-8):end) ]; end
    s = [ 'Instrument ' options.instrument sprintf('\n%s\n',cmdshort) sim_abstract sprintf('\nParameters:\n') class2str('  p',cell2struct(c(:),f(:),1),'no comment') dots ];
    ud.Information = cellstr(s);
    set(h, 'UserData', ud);
    t = uicontrol('String','Info','Callback',[ 'helpdlg(getfield(get(gcbf,''UserData''),''Information''),''' options.instrument ' parameters'');' ],'ToolTip', s);
    set(h, 'ToolBar','figure','menubar','figure');
    hold off
  end
  
  % evaluate the criteria specifications (monitors, expressions)
  criteria = zeros(numel(sim),1);
  for index=1:numel(sim)
    this = sim(index);
    if isfield(sim(index), 'CriteriaExpression')
      R = getalias(sim(index), 'CriteriaExpression');
      this = mcstas_eval(this, R); % use sandbox for eval (see below)
    else R = '';
    end
    
    this = double(this);
    this = sum(this(:));
    if isfield(options,'type') & strcmp(options.type,'maximize')
      this = -sum(this);
    end % else minimize
    criteria(index) = this;
  end
  
  % add aliases to the output objects (Parameters, Command line, ...)
  if nargout > 1
    if isnumeric(pars)
      this_pars = cell(size(pars));
      for index=1:length(this_pars)
        this_pars{index} = pars(index);
      end
    else
      this_pars = pars;
    end
    c = { this_pars{:} , options.fixed_pars{:} }; c=c(:);
    f = { options.variable_names{:} , options.fixed_names{:}}; f=f(:);
    this_pars = cell2struct(c, f, 1);
    % set(sim, 'Data.Parameters', this_pars);
    set(sim, 'Data.Criteria', criteria);
    set(sim, 'Data.Execute', cmd);
    set(sim, 'Data.Options', options);
    for index=1:length(f)
      setalias(sim, f{index}, [ 'Data.Parameters.' f{index} ], [ 'Instrument parameter ' f{index} ]);
    end
    setalias(sim, 'Parameters', 'Data.Parameters','Instrument parameters');
    setalias(sim, 'Criteria',   'Data.Criteria',  'Integral of monitors (criteria)');
    setalias(sim, 'Execute',    'Data.Execute',   'Command line used for Mcstas execution');
    setalias(sim, 'Options',    'Data.Options',   'Options used for Mcstas execution');
  end
end % mcstas_criteria
% end of mcstas_criteria (inline mcstas)

% ------------------------------------------------------------------------------
% function to search for a file recursively
function fileList = getAllFiles(dirName, File)

  % allow search in many directories
  if iscell(dirName)
    for d=1:length(dirName)
      fileList=getAllFiles(dirName{d}, File);
      if ~isempty(fileList)
        break
      end
    end
    return
  end
  
  dirData = dir(dirName);                 % Get the data for the current directory
  fileList= [];
  if ~isdir(dirName), dirName = fileparts(dirName); end
  if isempty(dirData), return; end
  dirIndex = [dirData.isdir];             % Find the index for directories
  fileList = {dirData(~dirIndex).name}';  % Get a list of the files
  if ~isempty(fileList)
    index = find(strcmp(File, fileList));
    if ~isempty(index)
      fileList = fullfile(dirName,fileList{index(1)});  % get the full path/file name
      return
    else
      fileList = [];
    end
  end
  subDirs = {dirData(dirIndex).name};          % Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});  % Find index of subdirectories
                                               %   that are not '.' or '..'
  
  for iDir = find(validIndex)                  % Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir}); % Get the subdirectory path
    fileList = getAllFiles(nextDir, File);     % Recursively call getAllFiles
    if ~isempty(fileList), return; end
  end

end

% ------------------------------------------------------------------------------
% evaluate property in a reduced environment
function this = mcstas_eval(this, expr)
  try
    eval([ 'this = this' expr ';' ]);  % calls subsref by eval (recursive subsref levels)
  catch
    this
    error([ mfilename ': Error when evaluating monitor definition this=this' expr ';' ])
  end
end % mcstas_eval
