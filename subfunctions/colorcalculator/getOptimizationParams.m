function options=getOptimizationParams(id)

% Sets parameters of automatic RGB video input optimization procedures to get required CIE1931 xyY values.
% function options=getOptimizationParams(id)
%
% This functions sets parameters of automatic RGB video input optimization procedures
% to get required CIE1931 xyY values. You can edit values in this fule when you want
% to change the optimization details. Or you can add your own optimization procedures
% in measurement_method_list.m and add the corresponding optimization parameters in
% this file. Please be careful that the input variable "id" should match with the order
% (cell member id) of the measurement methods listed in measurement_method_list.m. When
% you add your own method into the list, you also need to change this file adequately.
%
% [input]
% id      : ID of the optimization procedures listed in measurement_method_list.m, integer
%
% [output]
% options : option parameters set when the function the meas_methods{id}{2} is called.
%           for details, please see measurement_method_list.m.
%
%
% Created    : "2013-12-13 10:56:44 ban"
% Last Update: "2013-12-13 11:12:00 ban"

% check input variable.
if nargin<1 || isempty(id), help(mfilename()); return; end

% option parameter descriptions
switch id

  case 1 % meas_methods{1}={'Measure simply','calculator_measure_simply'};
    % defalt settings are as below.
    % for details, please see MeasureCIE1931xyY.

    % options=[]; % do nothing

    options=[];

  case 2 % meas_methods{2}={'[auto] Recursive linear estimation with unifrnd()','calculator_auto_estimation_linear'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimateLinear.

    % options.iteration=5;
    % options.samples=18;
    % options.rsmerror=1; % percent error
    % options.ss0=2.0; % search space, from ss0 to ss1
    % options.ss1=1.0;

    options.iteration=5;
    options.samples=18;
    options.rsmerror=1; % percent error
    options.ss0=2.0; % search space, from ss0 to ss1
    options.ss1=1.0;

  case 3 % meas_methods{3}={'[auto] Recursive linear estimation with Grid','calculator_auto_estimation_linear_grid'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimateLinearGrid.

    % options.iteration=5;
    % options.samples=18;
    % options.rsmerror=1; % percent error
    % options.ss0=2.0; % search space, from ss0 to ss1
    % options.ss1=1.0;

    options.iteration=5;
    options.samples=18;
    options.rsmerror=1; % percent error
    options.ss0=2.0; % search space, from ss0 to ss1
    options.ss1=1.0;

  case 4 % meas_methods{4}={'[auto] Adjust residuals by linear coefficients','calculator_auto_estimation_lincoeff'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimateLinearCoeff.

    % options=optimset; % empty structure
    % options.Display='iter';
    % options.TolFun =1e-2;
    % options.TolX   =1e-2;
    % options.MaxIter=100;
    % options.MaxFunEvals=100;
    % options.Hybrid = 'Coggins';
    % options.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
    % options.optimizer = 'fminpowell';

    options=optimset; % empty structure
    options.Display='iter';
    options.TolFun =1e-2;
    options.TolX   =1e-2;
    options.MaxIter=100;
    options.MaxFunEvals=100;
    options.Hybrid = 'Coggins';
    options.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
    options.optimizer = 'fminpowell';

  case 5 % meas_methods{5}={'[auto] Non-linear (Nelder-Mead Simplex)','calculator_auto_estimation_nonlinear'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimateNonLinear.

    % options=optimset('Display','iter','MaxFunEvals',250,'TolFun',0.1,'TolX',1e-2,'MaxIter',50,'DiffMinChange',1e-3);

    options=optimset('Display','iter','MaxFunEvals',250,'TolFun',0.1,'TolX',1e-2,'MaxIter',50,'DiffMinChange',1e-3);

  case 6 % meas_methods{6}={'[auto] Linear/non-linear hybrid','calculator_auto_estimation_hybrid'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimateHybrid.

    % options.lin.iteration=3;
    % options.lin.samples=18;
    % options.lin.rmserror=1; % percent error
    % options.lin.ss0=2.0; % search space, from ss0 to ss1
    % options.lin.ss1=1.0;
    % options.nonlin=optimset('Display','iter','MaxFunEvals',150,'TolFun',0.5,'TolX',1e-3,'MaxIter',50,'DiffMinChange',1e-3);

    options.lin.iteration=3;
    options.lin.samples=18;
    options.lin.rmserror=1; % percent error
    options.lin.ss0=2.0; % search space, from ss0 to ss1
    options.lin.ss1=1.0;
    options.nonlin=optimset('Display','iter','MaxFunEvals',150,'TolFun',0.5,'TolX',1e-3,'MaxIter',50,'DiffMinChange',1e-3);

  case 7 % meas_methods{7}={'[auto] Brent-Powell with Coggins/Golden-section','calculator_auto_estimation_powell'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimatePowell.

    % options=optimset; % empty structure
    % options.Display='iter';
    % options.TolFun =0.1;
    % options.TolX   =1e-3;
    % options.MaxIter=100;
    % options.MaxFunEvals=200;
    % options.Hybrid = 'Coggins';
    % options.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
    % options.optimizer = 'fminpowell';

    options=optimset; % empty structure
    options.Display='iter';
    options.TolFun =0.1;
    options.TolX   =1e-3;
    options.MaxIter=100;
    options.MaxFunEvals=200;
    options.Hybrid = 'Coggins';
    options.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
    options.optimizer = 'fminpowell';

  case 8 % meas_methods{8}={'[auto] Linear/Brent-Powell hybrid','calculator_auto_estimation_powell_hybrid'};
    % defalt settings are as below.
    % for details, please see AutoColorEstimatePowellHybrid.

    % options.lin.iteration=3;
    % options.lin.samples=18;
    % options.lin.rmserror=1; % percent error
    % options.lin.ss0=2.0; % search space, from ss0 to ss1
    % options.lin.ss1=1.0;
    % options.powell=optimset(); % empty structure
    % options.powell.Display='iter';
    % options.powell.TolFun =0.5;
    % options.powell.TolX   =1e-3;
    % options.powell.MaxIter=80;
    % options.powell.MaxFunEvals=200;
    % options.powell.Hybrid = 'Coggins';
    % options.powell.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
    % options.powell.optimizer = 'fminpowell';

    options.lin.iteration=3;
    options.lin.samples=18;
    options.lin.rmserror=1; % percent error
    options.lin.ss0=2.0; % search space, from ss0 to ss1
    options.lin.ss1=1.0;
    options.powell=optimset(); % empty structure
    options.powell.Display='iter';
    options.powell.TolFun =0.5;
    options.powell.TolX   =1e-3;
    options.powell.MaxIter=80;
    options.powell.MaxFunEvals=200;
    options.powell.Hybrid = 'Coggins';
    options.powell.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
    options.powell.optimizer = 'fminpowell';

  otherwise
    % defalt settings are as below.
    % options=[];

    options=[];

end

return
