function [X,FVAL,EXITFLAG,OUTPUT] = PSO(FUN,X0,LB,UB,OPTIONS,varargin)
%PSO finds a minimum of a function of several variables using the particle swarm 
% optimization (PSO) algorithm originally introduced in 1995 by Kennedy and 
% Eberhart. This algorithm was extended by Shi and Eberhart in 1998 through the
% introduction of inertia factors to dampen the velocities of the particles.
% In 2002, Clerc and Kennedy introduced a constriction factor in PSO, which was
% later on shown to be superior to the inertia factors. Therefore, the algorithm
% using a constriction factor was implemented here.
%
%   PSO attempts to solve problems of the form:
%       min F(X) subject to: LB <= X <= UB
%        X
%
%   X=PSO(FUN,X0) start at X0 and finds a minimum X to the function FUN. 
%   FUN accepts input X and returns a scalar function value F evaluated at X.
%   X0 may be a scalar, vector, or matrix.
%   
%   X=PSO(FUN,X0,LB,UB) defines a set of lower and upper bounds on the 
%   design variables, X, so that a solution is found in the range 
%   LB <= X <= UB. Use empty matrices for LB and UB if no bounds exist. 
%   Set LB(i) = -Inf if X(i) is unbounded below; set UB(i) = Inf if X(i) is 
%   unbounded above.
%   
%   X=PSO(FUN,X0,LB,UB,OPTIONS) minimizes with the default optimization
%   parameters replaced by values in the structure OPTIONS, an argument 
%   created with the PSOSET function. See PSOSET for details. 
%   Used options are PopulationSize, SwarmC1, SwarmC2, MaxIter,
%   MaxFunEvals, TolX, TolFun, Display and OutputFcn.
%   Use OPTIONS = [] as a place holder if no options are set.
%   
%   X=PSO(FUN,X0,LB,UB,OPTIONS,varargin) is used to supply a variable 
%   number of input arguments to the objective function FUN.
%   
%   [X,FVAL]=PSO(FUN,X0,...) returns the value of the objective 
%   function FUN at the solution X.
%   
%   [X,FVAL,EXITFLAG]=PSO(FUN,X0,...) returns an EXITFLAG that describes the 
%   exit condition of PSO. Possible values of EXITFLAG and the corresponding 
%   exit conditions are:
%   
%     1  Change in the objective function value less than the specified tolerance.
%     2  Change in X less than the specified tolerance.
%     0  Maximum number of function evaluations or iterations reached.
%    -1  Maximum time exceeded.
%   
%   [X,FVAL,EXITFLAG,OUTPUT]=PSO(FUN,X0,...) returns a structure OUTPUT with 
%   the number of iterations taken in OUTPUT.nITERATIONS, the number of function
%   evaluations in OUTPUT.nFUN_EVALS, the coordinates of the different particles in 
%   the swarm in OUTPUT.SWARM, the corresponding fitness values in OUTPUT.FITNESS, 
%   the particle's best position and its corresponding fitness in OUTPUT.PBEST and
%   OUTPUT.PBEST_FITNESS, the best position ever achieved by the swarm in 
%   OUTPUT.GBEST and its corresponding fitness in OUTPUT.GBEST_FITNESS, the amount
%   of time needed in OUTPUT.TIME and the options used in OUTPUT.OPTIONS.
% 



% Copyright (C) 2006 Brecht Donckels, BIOMATH, brecht.donckels@ugent.be
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. 
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
% USA.



% handle variable input arguments

if nargin < 5,
    OPTIONS = [];
    if nargin < 4,
        UB = 1e5;
        if nargin < 3,
            LB = -1e5;
        end
    end
end

% check input arguments

if ~ischar(FUN) & ~isa(FUN,'function_handle'),
    error('''FUN'' incorrectly specified in ''PSO''');
end
if ~isfloat(X0),
    error('''X0'' incorrectly specified in ''PSO''');
end
if ~isfloat(LB),
    error('''LB'' incorrectly specified in ''PSO''');
end
if ~isfloat(UB),
    error('''UB'' incorrectly specified in ''PSO''');
end
if length(X0) ~= length(LB),
    error('''LB'' and ''X0'' have incompatible dimensions in ''PSO''');
end
if length(X0) ~= length(UB),
    error('''UB'' and ''X0'' have incompatible dimensions in ''PSO''');
end

% declaration of global variables

global NDIM nFUN_EVALS

% set EXITFLAG to default value

EXITFLAG = 0;

% determine number of variables to be optimized

NDIM = length(X0);

% seed the random number generator

rand('state',sum(100*clock));

% initialize swarm (each row of swarm corresponds to one particle)

SWARM = zeros(OPTIONS.PopulationSize,NDIM,OPTIONS.MaxIter);

for i = 1:OPTIONS.PopulationSize,
    if i == 1,
        SWARM(1,:,1) = X0(:)';
    else
        SWARM(i,:,1) = LB(:)' + rand(1,NDIM).*(UB(:)'-LB(:)');
    end
end

% initialize VELOCITIES

VELOCITIES = zeros(OPTIONS.PopulationSize,NDIM,OPTIONS.MaxIter);

% initialize FITNESS, PBEST_FITNESS, GBEST_FITNESS, INDEX_PBEST, index_gbest_particle and INDEX_GBEST_ITERATION

FITNESS = nan(OPTIONS.PopulationSize,OPTIONS.MaxIter);
PBEST = nan(OPTIONS.PopulationSize,NDIM,OPTIONS.MaxIter);
GBEST = nan(OPTIONS.MaxIter,NDIM);
PBEST_FITNESS = nan(OPTIONS.PopulationSize,OPTIONS.MaxIter);
GBEST_FITNESS = nan(OPTIONS.PopulationSize,1);
INDEX_PBEST = nan(OPTIONS.PopulationSize,OPTIONS.MaxIter);
INDEX_GBEST_PARTICLE = nan(OPTIONS.MaxIter,1);
INDEX_GBEST_ITERATION = nan(OPTIONS.MaxIter,1);

% calculate constriction factor from acceleration coefficients

if OPTIONS.SwarmC1+OPTIONS.SwarmC2 <= 4,
    % Display message
    if strcmp(OPTIONS.Dispplay,'iter') | strcmp(OPTIONS.Display,'notify')
      disp('Sum of Cognitive Acceleration Coefficient and Social Acceleration Coefficient is less then or equal to 4.')
      disp('Their values were adjusted automatically to satisfy this condition.');
      disp(' ')
    end
    % the values are adjusted so that the sum is equal to 4.1, keeping the ratio SwarmC1/SwarmC2 constant
    OPTIONS.SwarmC1 = OPTIONS.SwarmC1*4.1/(OPTIONS.SwarmC1+OPTIONS.SwarmC2);
    OPTIONS.SwarmC2 = OPTIONS.SwarmC2*4.1/(OPTIONS.SwarmC1+OPTIONS.SwarmC2);
    % calculate constriction factor
    k = 1; % k can take values between 0 and 1, but is usually set to one (Montes de Oca et al., 2006)
    OPTIONS.ConstrictionFactor = 2*k/(abs(2-(OPTIONS.SwarmC1+OPTIONS.SwarmC2)-sqrt((OPTIONS.SwarmC1+OPTIONS.SwarmC2)^2-4*(OPTIONS.SwarmC1+OPTIONS.SwarmC2))));
else
    % calculate constriction factor
    k = 1; % k can take values between 0 and 1, but is usually set to one (Montes de Oca et al., 2006)
    OPTIONS.ConstrictionFactor = 2*k/(abs(2-(OPTIONS.SwarmC1+OPTIONS.SwarmC2)-sqrt((OPTIONS.SwarmC1+OPTIONS.SwarmC2)^2-4*(OPTIONS.SwarmC1+OPTIONS.SwarmC2))));
end

% initialize counters

nITERATIONS = 0;
nFUN_EVALS = 0;
message='';

% for each iteration....

for i = 1:OPTIONS.MaxIter,
    
    % if a termination criterium was met, the value of EXITFLAG should have changed
    % from its default value of -2 to -1, 0, 1 or 2
    
    if EXITFLAG
        break
    end
    
    % calculate FITNESS values for all particles in SWARM 
    % (each row of FITNESS corresponds to the FITNESS value of one particle)
    % (each column of FITNESS corresponds to the FITNESS values of the particles in one iteration)
    
    for j = 1:OPTIONS.PopulationSize,
        FITNESS(j,i) = CALCULATE_COST(FUN,SWARM(j,:,i),LB,UB,varargin{:});
    end
    
    % identify particle's location at which the best FITNESS has been achieved (PBEST)
    
    for j = 1:OPTIONS.PopulationSize,
        [PBEST_FITNESS(j,i),INDEX_PBEST(j,i)] = min(FITNESS(j,:));
        PBEST(j,:,i) = SWARM(j,:,INDEX_PBEST(j,i));
    end
    
    % identify the particle from the SWARM at which the best FITNESS has been achieved so far (GBEST)
        
    [GBEST_FITNESS(i),index_gbest] = min(reshape(FITNESS,numel(FITNESS),1));
    [INDEX_GBEST_PARTICLE(i),INDEX_GBEST_ITERATION(i)] = ind2sub(size(FITNESS),index_gbest);
    GBEST(i,:) = SWARM(INDEX_GBEST_PARTICLE(i),:,INDEX_GBEST_ITERATION(i));
        
    % update the VELOCITIES
    
    VELOCITIES(:,:,i+1) = OPTIONS.ConstrictionFactor.*(VELOCITIES(:,:,i) + OPTIONS.SwarmC1.*rand(OPTIONS.PopulationSize,NDIM).*(PBEST(:,:,i)-SWARM(:,:,i)) + OPTIONS.SwarmC2.*rand(OPTIONS.PopulationSize,NDIM).*(repmat(GBEST(i,:),[OPTIONS.PopulationSize 1 1],1)-SWARM(:,:,i)));
    
    % update particle positions
    
    SWARM(:,:,i+1) = SWARM(:,:,i)+VELOCITIES(:,:,i+1);
    
    % to make sure that particles stay within specified bounds...
    %   (suppose that the particle's new position is outside the boundaries,
    %    then the particle's position is adjusted by assuming that the boundary
    %    acts like a wall or mirror) (selfmade solution)
    
    for j = 1:OPTIONS.PopulationSize,
        for k = 1:NDIM,
            % check upper boundary
            if length(UB) == 1,
                if SWARM(j,k,i+1) > UB,
                    SWARM(j,k,i+1) = UB-rand*(SWARM(j,k,i+1)-UB);
                    VELOCITIES(j,k,i+1) = SWARM(j,k,i+1)-SWARM(j,k,i);
                end
            else
                if SWARM(j,k,i+1) > UB(k),
                    SWARM(j,k,i+1) = UB(k)-rand*(SWARM(j,k,i+1)-UB(k));
                    VELOCITIES(j,k,i+1) = SWARM(j,k,i+1)-SWARM(j,k,i);
                end
            end
            % check lower boundary
            if length(UB) == 1,
                if SWARM(j,k,i+1) < LB,
                    SWARM(j,k,i+1) = LB+rand*(LB-SWARM(j,k,i+1));
                    VELOCITIES(j,k,i+1) = SWARM(j,k,i+1)-SWARM(j,k,i);
                end
            else
                if SWARM(j,k,i+1) < LB(k),
                    SWARM(j,k,i+1) = LB(k)+rand*(LB(k)-SWARM(j,k,i+1));
                    VELOCITIES(j,k,i+1) = SWARM(j,k,i+1)-SWARM(j,k,i);
                end
            end
        end
    end    
        
    % update counters
    
    nITERATIONS = nITERATIONS+1;
    
    % give user feedback on screen if requested
    
    if 0 && strcmp(OPTIONS.Display,'iter'),
        if nITERATIONS == 1,
            disp(' Nr Iter  Nr Fun Eval    Current best function    Current worst function       Best function');
            disp(sprintf(' %5.0f     %5.0f             %12.6g              %12.6g           %15.6g',nITERATIONS,nFUN_EVALS,min(FITNESS(:,i)),max(FITNESS(:,i)),GBEST_FITNESS(i)));
        else
            disp(sprintf(' %5.0f     %5.0f             %12.6g              %12.6g           %15.6g',nITERATIONS,nFUN_EVALS,min(FITNESS(:,i)),max(FITNESS(:,i)),GBEST_FITNESS(i)));
        end
    end
    
    % end the optimization if one of the stopping criteria is met
    %% 1. difference between best and worst function evaluation in simplex is smaller than TolFun 
    %% 2. maximum difference between the coordinates of the vertices in simplex is less than TolX
    %% 3. no convergence,but maximum number of iterations has been reached
    
    if OPTIONS.TolX >0 & max(max(abs(diff(SWARM(:,:,i),1,1)))) < OPTIONS.TolX,
        message='Change in X less than the specified tolerance (TolX).';
        EXITFLAG = -5;
    end
    if OPTIONS.TolFun & abs(min(FITNESS(:,i))-GBEST_FITNESS(i)) < abs(OPTIONS.TolFun) ...
       & abs(min(FITNESS(:,i))-GBEST_FITNESS(i)) > 0
      EXITFLAG=-12;
      message = [ 'Termination function change tolerance criteria reached (options.TolFun=' ...
                num2str(OPTIONS.TolFun) ')' ];
    end
    
    if EXITFLAG
      break
    end

end

% return solution

X = GBEST(i,:);
FVAL = GBEST_FITNESS(i);

% store number of function evaluations

OUTPUT.funcCount = nFUN_EVALS;

% store number of iterations

OUTPUT.iterations = nITERATIONS;
OUTPUT.message    = message;
OUTPUT.algorithm  = OPTIONS.algorithm;

return

% ==============================================================================

% COST FUNCTION EVALUATION
% ------------------------

function [YTRY] = CALCULATE_COST(FUN,PTRY,LB,UB,varargin)

global NDIM nFUN_EVALS

% add one to number of function evaluations
nFUN_EVALS = nFUN_EVALS + 1;

for i = 1:NDIM,
    % check lower bounds
    if PTRY(i) < LB(i),
        YTRY = 1e12+(LB(i)-PTRY(i))*1e6;
        return
    end
    % check upper bounds
    if PTRY(i) > UB(i),
        YTRY = 1e12+(PTRY(i)-UB(i))*1e6;
        return
    end
end

% calculate cost associated with PTRY
YTRY = feval(FUN,PTRY,varargin{:});

return

