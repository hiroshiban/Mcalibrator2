function [x,fval,i,output]=hPSO(fitnessfun,pars,options,varargin)
%Syntax: [x,fval,exitflag,output]=hPSO(fitnessfun,nvars,options,varargin)
%___________________________________________________________________
%
% A hybrid Particle Swarm Optimization algorithm for finding the minimum of
% the function 'fitnessfun' in the real space.
%
% x is the scalar/vector of the functon minimum
% fval is the function minimum
% gfx contains the best particle for each flight (columns 2:end) and the
%  corresponding solutions (1st column)
% output structure contains the following information
%   reason : is the reason for stopping
%   flights: the nuber of flights before stopping
%   time   : the total time before stopping
% fitnessfun is the function to be minimized
% nvars is the number of variables of the problem
% options are specified in the file "PSOoptions.m"
%
%
% Reference:
% Kennedy J., Eberhart R.C. (1995): Particle swarm optimization. In: Proc.
% IEEE Conf. on Neural Networks, IV, Piscataway, NJ, pp. 1942-1948
%
%
% Alexandros Leontitsis
% Department of Education
% University of Ioannina
% 45110- Dourouti
% Ioannina
% Greece
% 
% University e-mail: me00743@cc.uoi.gr
% Lifetime e-mail: leoaleq@yahoo.com
% Homepage: http://www.geocities.com/CapeCanaveral/Lab/1421
% 
% 17 Nov, 2004.

nvars=length(pars);

if size(options.space,1)==1
    options.space=kron(options.space(:)', ones(nvars,1));
elseif size(options.space,1)~=nvars
    error('The rows of options.space are not equal to nvars.');
end

if size(options.maxv,1)==1
    options.maxv=options.maxv*ones(nvars,1);
elseif size(options.maxv,1)~=nvars
    error('The rows of options.maxv are not equal to nvars.');
end

c1    = options.c1;
c2    = options.c2;
w     = options.w;
maxv  = options.maxv;
space = options.space;
popul = options.bees;
flights = options.MaxIter;
Goal  = options.TolFun;

funcount=0; istop=0; x=pars;

% Initial population (random start)
ru=rand(popul,size(space,1));
pop=ones(popul,1)*space(:,1)'+ru.*(ones(popul,1)*(space(:,2)-space(:,1))');
%pop(1,:)=pars(:); % force first particule to be the starting parameters

% Hill climb of each solution (bee)
if isa(options.Hybrid, 'function_handle') | exist(options.Hybrid) == 2
  options_hybrid = feval(options.Hybrid,'defaults');
  options_hybrid.Display='off';
  for i=1:popul
      [pop(i,:),fxi(i,1),dummy,out]=feval(options.Hybrid,fitnessfun,pop(i,:),options_hybrid);
      funcount = funcount+out.funcCount;
  end
end

% constraints within search domain
pop=min(pop,ones(popul,1)*space(:,2)');
pop=max(pop,ones(popul,1)*space(:,1)');
for i=1:popul
  fxi(i,1)=feval(fitnessfun,pop(i,:));
end
funcount = funcount+popul+1;

% Local minima
p=pop;
fxip=fxi;

% Initialize the velocities
v=zeros(popul,size(space,1));

% Isolate the best solution
[Y,I]=min(fxi);
gfx(1,:)=[Y pop(I,:)];
P=ones(popul,1)*pop(I,:);
fval=feval(fitnessfun, pars);

StallFli = 0;
message = 'Optimization terminated: maximum number of flights reached.';

% For each flight
for i=2:flights
    x_prev=x;
    f_prev=fval;
    % Estimate the velocities
    r1=rand(popul,size(space,1));
    r2=rand(popul,size(space,1));
    v=v*w+c1*r1.*(p-pop)+c2*r2.*(P-pop);
    v=max(v,-ones(popul,1)*maxv');
    v=min(v,ones(popul,1)*maxv');
    
    % Add the velocities to the population 
    pop=pop+v;
    
    % Drag the particles into the search space
    pop=min(pop,ones(popul,1)*space(:,2)');
    pop=max(pop,ones(popul,1)*space(:,1)');
    
    % Hill climb search for the new population
    pnew=p;
    fxipnew=fxip;
    if isa(options.Hybrid, 'function_handle') | exist(options.Hybrid) == 2
      for j=1:popul
          [pop(j,:),fxi(j,1),dummy,out]     =feval(options.Hybrid,fitnessfun,pop(j,:),options_hybrid);
          funcount = funcount+out.funcCount;
          [pnew(j,:),fxipnew(j,1),dummy,out]=feval(options.Hybrid,fitnessfun,p(j,:),options_hybrid);
          funcount = funcount+out.funcCount;
      end
    else
      pnew=p;
    end
    pop=min(pop,ones(popul,1)*space(:,2)');
    pop=max(pop,ones(popul,1)*space(:,1)');
    pnew=min(pnew,ones(popul,1)*space(:,2)');
    pnew=max(pnew,ones(popul,1)*space(:,1)');
    for j=1:popul
      fxi(j,:)    =feval(fitnessfun,pop(j,:));
      fxipnew(j,:)=feval(fitnessfun,p(j,:));
    end
    funcount = funcount+2*popul;
    
    % Min(fxi,fxip)
    s=find(fxi<fxip);
    p(s,:)=pop(s,:);
    fxip(s)=fxi(s);
    
    % Min(fxipnew,fxip);
    s=find(fxipnew<fxip);
    p(s,:)=pnew(s,:);
    fxip(s)=fxipnew(s);
    
    % Isolate the best solution
    [Y,I]=min(fxip);
    gfx(i,:)=[Y p(I,:)];
    P=ones(popul,1)*p(I,:);
    
    % std stopping conditions
    % Get the point that correspond to the minimum of the function
    x=gfx(end,2:end);
    % Get the minimum of the function
    fval=gfx(end,1);
    
    % Termination conditions
    if gfx(i,1)==gfx(i-1,1)
        StallFli = StallFli+1;
    end    
    if StallFli >= options.StallFliLimit
        message = 'Optimization terminated: Stall Flights Limit reached.';
        istop=-10;
    end
      
    if istop
      break
    end
end
if istop==0, message='Algorithm terminated normally'; end
output.iterations= i;
output.message   = message;
output.funcCount = funcount;
output.algorithm = options.algorithm;
