function [X,FVAL,EXITFLAG,OUTPUT] = SCE(FUN,X0,LB,UB,OPTIONS,varargin)
%SCE finds a minimum of a function of several variables using the shuffled
% complex evolution (SCE) algorithm originally introduced in 1992 by Duan et al. 
%
%   SCE attempts to solve problems of the form:
%       min F(X) subject to: LB <= X <= UB
%        X
%
%   X=SCE(FUN,X0) start at X0 and finds a minimum X to the function FUN. 
%   FUN accepts input X and returns a scalar function value F evaluated at X.
%   X0 may be a scalar, vector, or matrix.
%   
%   X=SCE(FUN,X0,LB,UB) defines a set of lower and upper bounds on the 
%   design variables, X, so that a solution is found in the range 
%   LB <= X <= UB. Use empty matrices for LB and UB if no bounds exist. 
%   Set LB(i) = -Inf if X(i) is unbounded below; set UB(i) = Inf if X(i) is 
%   unbounded above.
%   
%   X=SCE(FUN,X0,LB,UB,OPTIONS) minimizes with the default optimization
%   parameters replaced by values in the structure OPTIONS, an argument 
%   created with the SCESET function. See SCESET for details. 
%   Used options are PopulationSize, nITER_INNER_LOOP, MaxIter,
%   MAX_TIME, MaxFunEvals, TolX, TolFun, Display and OutputFcn.
%   Use OPTIONS = [] as a place holder if no options are set.
%   
%   X=SCE(FUN,X0,LB,UB,OPTIONS,varargin) is used to supply a variable 
%   number of input arguments to the objective function FUN.
%   
%   [X,FVAL]=SCE(FUN,X0,...) returns the value of the objective 
%   function FUN at the solution X.
%   
%   [X,FVAL,EXITFLAG]=SCE(FUN,X0,...) returns an EXITFLAG that describes the 
%   exit condition of SCE. Possible values of EXITFLAG and the corresponding 
%   exit conditions are:
%   
%     1  Change in the objective function value less than the specified tolerance.
%     2  Change in X less than the specified tolerance.
%     0  Maximum number of function evaluations or iterations reached.
%    -1  Maximum time exceeded.
%   
%   [X,FVAL,EXITFLAG,OUTPUT]=SCE(FUN,X0,...) returns a structure OUTPUT with 
%   the number of iterations taken in OUTPUT.nITERATIONS, the number of function
%   evaluations in OUTPUT.nFUN_EVALS, the different points in the population 
%   at every iteration and their fitness in OUTPUT.POPULATION and 
%   OUTPUT.POPULATION_FITNESS respectively, the amount of time needed in 
%   OUTPUT.TIME and the options used in OUTPUT.OPTIONS.
% 
%   See also SCESET, SCEGET



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
    error('''FUN'' incorrectly specified in ''SCE''');
end
if ~isfloat(X0),
    error('''X0'' incorrectly specified in ''SCE''');
end
if ~isfloat(LB),
    error('''LB'' incorrectly specified in ''SCE''');
end
if ~isfloat(UB),
    error('''UB'' incorrectly specified in ''SCE''');
end
if length(X0) ~= length(LB),
    error('''LB'' and ''X0'' have incompatible dimensions in ''SCE''');
end
if length(X0) ~= length(UB),
    error('''UB'' and ''X0'' have incompatible dimensions in ''SCE''');
end

% declaration of global variables

global NDIM nFUN_EVALS

% set EXITFLAG to default value

EXITFLAG = 0;

% determine number of variables to be optimized

NDIM = length(X0);

% seed the random number generator

rand('state',sum(100*clock));

% define number of points in each complex if not provided

OPTIONS.nPOINTS_COMPLEX = 2*NDIM+1;

% define number of points in each simplex if not provided

OPTIONS.nPOINTS_SIMPLEX = NDIM+1;

% define total number of points

nPOINTS = OPTIONS.PopulationSize*OPTIONS.nPOINTS_COMPLEX;

% initialize population

POPULATION = nan(nPOINTS,NDIM,OPTIONS.MaxIter);

for i = 1:nPOINTS,
    if i == 1,
        POPULATION(i,:,1) = X0(:)';
    else
        POPULATION(i,:,1) = LB(:)'+rand(1,NDIM).*(UB(:)'-LB(:)');
    end
end

% initialize counters

nITERATIONS = 0;
nFUN_EVALS = 0;
message='';

% calculate cost for each point in initial population

POPULATION_FITNESS = nan(nPOINTS,OPTIONS.MaxIter);

for i = 1:nPOINTS;
    POPULATION_FITNESS(i,1) = CALCULATE_COST(FUN,POPULATION(i,:,1),LB,UB,varargin{:});
end

% sort the population in order of increasing function values

[POPULATION_FITNESS(:,1),idx] = sort(POPULATION_FITNESS(:,1));
POPULATION(:,:,1) = POPULATION(idx,:,1);

% for each iteration...

for i = 2:OPTIONS.MaxIter,
    
    % add one to number of iterations counter
    
    nITERATIONS = nITERATIONS + 1;
    
    % The population matrix POPULATION will now be rearranged into so-called complexes.     
    % For each complex ...
    
    for j = 1:OPTIONS.PopulationSize,
        
        % construct j-th complex from POPULATION
        
        k1 = 1:OPTIONS.nPOINTS_COMPLEX;
        k2 = (k1-1)*OPTIONS.PopulationSize+j;
        
        COMPLEX(k1,:) = POPULATION(k2,:,i-1);
        COMPLEX_FITNESS(k1,1) = POPULATION_FITNESS(k2,i-1);
        
        % Each complex evolves a number of steps according to the competitive 
        % complex evolution (CCE) algorithm as described in Duan et al. (1992). 
        % Therefore, a number of 'parents' are selected from each complex which 
        % form a simplex. The selection of the parents is done so that the better
        % points in the complex have a higher probability to be selected as a 
        % parent. The paper of Duan et al. (1992) describes how a trapezoidal 
        % probability distribution can be used for this purpose. The implementation
        % found on the internet (implemented by Duan himself) however used a 
        % somewhat different probability distribution which is used here as well.
        
        for k = 1:OPTIONS.nITER_INNER_LOOP,
            
            % select simplex by sampling the complex
            
            LOCATION(1) = 1; % the LOCATION of the selected point in the complex

            for l = 2:OPTIONS.nPOINTS_SIMPLEX;
                ALREADY_PARENT = 0;
                while ~ALREADY_PARENT,
                    DUMMY = 1 + floor(OPTIONS.nPOINTS_COMPLEX+0.5-sqrt((OPTIONS.nPOINTS_COMPLEX+0.5)^2 - OPTIONS.nPOINTS_COMPLEX*(OPTIONS.nPOINTS_COMPLEX+1)*rand));
                    if isempty(find(LOCATION(1:l-1) == DUMMY,1,'first')),
                        ALREADY_PARENT = 1;
                    end
                end
                LOCATION(l) = DUMMY;
            end
            
            LOCATION = sort(LOCATION);
            
            % construct the simplex
            
            SIMPLEX = COMPLEX(LOCATION,:);
            SIMPLEX_FITNESS = COMPLEX_FITNESS(LOCATION);
            
            % generate new point for simplex
            
            %% first extrapolate by a factor -1 through the face of the simplex
            %% across from the high point,i.e.,reflect the simplex from the high point
            [SFTRY,SXTRY] = AMOTRY(FUN,SIMPLEX,-1,LB,UB,varargin{:});
            
            %% check the result
            if SFTRY <= SIMPLEX_FITNESS(1),
                %% gives a result better than the best point,so try an additional
                %% extrapolation by a factor 2
                [SFTRYEXP,SXTRYEXP] = AMOTRY(FUN,SIMPLEX,-2,LB,UB,varargin{:});
                if SFTRYEXP < SFTRY,
                    SIMPLEX(end,:) = SXTRYEXP;
                    SIMPLEX_FITNESS(end) = SFTRYEXP;
                    ALGOSTEP = 'reflection and expansion';
                else
                    SIMPLEX(end,:) = SXTRY;
                    SIMPLEX_FITNESS(end) = SFTRY;
                    ALGOSTEP = 'reflection';
                end
            elseif SFTRY >= SIMPLEX_FITNESS(NDIM),
                %% the reflected point is worse than the second-highest, so look
                %% for an intermediate lower point, i.e., do a one-dimensional
                %% contraction
                [SFTRYCONTR,SXTRYCONTR] = AMOTRY(FUN,SIMPLEX,-0.5,LB,UB,varargin{:});
                if SFTRYCONTR < SIMPLEX_FITNESS(end),
                    SIMPLEX(end,:) = SXTRYCONTR;
                    SIMPLEX_FITNESS(end) = SFTRYCONTR;
                    ALGOSTEP = 'one dimensional contraction';
                else
                    %% can't seem to get rid of that high point, so better contract
                    %% around the lowest (best) point
                    SX_HELP = ones(NDIM,NDIM)*diag(SIMPLEX(1,:));
                    SIMPLEX(2:end,:) = 0.5*(SIMPLEX(2:end,:)+SX_HELP);
                    for k=2:NDIM,
                        SIMPLEX_FITNESS(k) = CALCULATE_COST(FUN,SIMPLEX(k,:),LB,UB,varargin{:});
                    end
                    ALGOSTEP = 'multiple contraction';
                end
            else
                %% if ytry better than second-highest point, use this point
                SIMPLEX(end,:) = SXTRY;
                SIMPLEX_FITNESS(end) = SFTRY;
                ALGOSTEP = 'reflection';
            end
            
            % replace the simplex into the complex
            
            COMPLEX(LOCATION,:) = SIMPLEX;
            COMPLEX_FITNESS(LOCATION) = SIMPLEX_FITNESS;
            
            % sort the complex;
            
            [COMPLEX_FITNESS,idx] = sort(COMPLEX_FITNESS);
            COMPLEX = COMPLEX(idx,:);
            
        end
        
        % replace the complex back into the population
        
        POPULATION(k2,:,i) = COMPLEX(k1,:);
        POPULATION_FITNESS(k2,i) = COMPLEX_FITNESS(k1);
        
    end
    
    % At this point, the population was divided in several complexes, each of which
    % underwent a number of iteration of the simplex (Metropolis) algorithm. Now,
    % the points in the population are sorted, the termination criteria are checked
    % and output is given on the screen if requested.
    
    % sort the population
    
    [POPULATION_FITNESS(:,i),idx] = sort(POPULATION_FITNESS(:,i));
    POPULATION(:,:,i) = POPULATION(idx,:,i);
    
    % give user feedback on screen if requested
    
    if 0 & strcmp(OPTIONS.Display,'iter')
        if nITERATIONS == 1,
            disp(' Nr Iter  Nr Fun Eval    Current best function    Current worst function       Best function');
            disp(sprintf(' %5.0f     %5.0f             %12.6g              %12.6g           %15.6g',nITERATIONS,nFUN_EVALS,min(POPULATION_FITNESS(:,i)),max(POPULATION_FITNESS(:,i)),min(min(POPULATION_FITNESS))));
        else
            disp(sprintf(' %5.0f     %5.0f             %12.6g              %12.6g           %15.6g',nITERATIONS,nFUN_EVALS,min(POPULATION_FITNESS(:,i)),max(POPULATION_FITNESS(:,i)),min(min(POPULATION_FITNESS))));
        end
    end
    
    % end the optimization if one of the stopping criteria is met
    %% 1. difference between best and worst function evaluation in population is smaller than TolFun 
    %% 2. maximum difference between the coordinates of the vertices in simplex is less than TolX
    %% 3. no convergence,but maximum number of iterations has been reached
    %% 4. no convergence,but maximum time has been reached
    
    if ~EXITFLAG
      if max(max(abs( POPULATION(1,:,i) - POPULATION(2,:,i) ))) < OPTIONS.TolX,
          message=[ 'Change in X less than the specified tolerance (TolX=' num2str(OPTIONS.TolX) ')' ];
          EXITFLAG = -5;
      end
      
      if OPTIONS.TolFun & abs(min(POPULATION_FITNESS(:,i))-min(min(POPULATION_FITNESS))) < abs(OPTIONS.TolFun) ...
         & abs(min(POPULATION_FITNESS(:,i))-min(min(POPULATION_FITNESS))) > 0
        EXITFLAG=-12;
        message = [ 'Termination function change tolerance criteria reached (options.TolFun=' ...
                  num2str(OPTIONS.TolFun) ')' ];
      end

    end
    
    if EXITFLAG
      break
    end
    
end

% return best solution

X    = POPULATION(1,:,i);
FVAL = POPULATION_FITNESS(1,i);

% store number of function evaluations

OUTPUT.funcCount = nFUN_EVALS;

% store number of iterations

OUTPUT.iterations = nITERATIONS;
OUTPUT.message    = message;
OUTPUT.algorithm  = OPTIONS.algorithm;
return

% ==============================================================================

% AMOTRY FUNCTION
% ---------------

function [YTRY,PTRY] = AMOTRY(FUN,P,FAC,LB,UB,varargin)
% Extrapolates by a factor FAC through the face of the simplex across from 
% the high point, tries it, and replaces the high point if the new point is 
% better.

global NDIM

% calculate coordinates of new vertex
PSUM = sum(P(1:NDIM,:))/NDIM;
PTRY = PSUM*(1-FAC)+P(end,:)*FAC;

% evaluate the function at the trial point.
YTRY = CALCULATE_COST(FUN,PTRY,LB,UB,varargin{:});

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
