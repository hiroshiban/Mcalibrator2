function [pars, fval, iterations, output] = GA(fun, pars, options, constraints)
% Genetic Algorithm(real coding)
% By: Javad Ivakpour
% E-mail: javad7@gmail.com
% May 2006
% Goal: find maximum of function that introduced in fun00.m file in current
% directory and can be plotted in plot00
% this file is also include the random search for comparision


%------------------------        parameters        ------------------------
% befor using this function you must specified your function in fun00.m
% file in current directory and then set the parameters
var=length(pars);            % Number of variables (this item must be equal to the
                  %   number of variables that is used in the function
n=options.PopulationSize;            % Number of population

nmutationG=20;                  %number of mutation children(Gaussian)
nmutationR=20;                  %number of mutation children(random)
nelit=2;                        %number of elitism children
valuemin=constraints.min(:);       % min possible value of variables
valuemax=constraints.max(:);       % max possible value of variables
pars=pars(:);
fval=feval(fun, pars);
%-------------------------------------------------------------------------
nmutation= nmutationG+nmutationR;
max1     = zeros(nelit,var);
parent   = zeros(n,var);
p        = zeros(n,var);
sigma=(valuemax-valuemin)/10;    %Parameter that related to Gaussian
                                 %   function and used in mutation step
max1=zeros(nelit,var);
parent=zeros(n,var);
for l=1:var
    p(:,l)=valuemin(l)+rand(n,1).*(valuemax(l)-valuemin(l));
end
p(1,:)=pars;  % the starting configuration is the first guess
g=0;
iterations=0;
funcount  =0;

best_pars = pars;
best_fval = fval;

%-------------   ****    termination criteria   ****-------------
while 1
    pars_prev=pars(:)';
    fval_prev = fval;
    sigma=sigma./(1.05);% reducing the sigma value
    %  ------  **** % reducing the number of mutation()random   **** ----
    g=g+1;
    if g>10 & nmutationR>0
        g=0;
        nmutationR=nmutationR-1;
        nmutation=nmutationG+nmutationR;
    end


    %-------------   ****    function evaluation   ****-------------
    for i=1:n
        y(i)=-feval(fun,p(i,:));  % search maximum of -function
    end

    maxy=max(y);
    miny=min(y);
    
    s=sort(y);
    fvalsorted(1:nelit)=s(n:-1:n-nelit+1);
    if nelit==0
        fvalsorted(1)=s(n);
        for i=1:n
            if y(i)==fvalsorted(1)
                max1(1,:)=p(i,:);
            end
        end
    end
    for k=1:nelit
        for i=1:n
            if y(i)==fvalsorted(k)
                max1(k,:)=p(i,:);
            end
        end
    end
    
    y=y-miny*1.02;
    sumd=y./sum(y);


    %-------------   ****   Selection: Roulette wheel   ****-------------
    for l=1:n
        sel=rand;
        sumds=0;
        j=1;
        while sumds<sel
            sumds=sumds+sumd(j);
            j=j+1;
        end
        parent(l,:)=p(j-1,:);
    end
    p=zeros(n,var);

    %-------------   ****    regeneration   ****-------------
    for l=1:var


        %-------------   ****    cross-over   ****-------------
        for j=1:ceil((n-nmutation-nelit)/2)
            t=rand*1.5-0.25;
            p(2*j-1,l)=t*parent(2*j-1,l)+(1-t)*parent(2*j,l);
            p(2*j,l)=t*parent(2*j,l)+(1-t)*parent(2*j-1,l);
        end


        %-------------   ****    elitism   ****-------------
        for k=1:nelit
            p((n-nmutation-k+1),l)=max1(k,l);
        end


        %-------------   ****    mutation (Gaussian)  ****-------------
        phi=1-2*rand(nmutation-nmutationR,1);
        z = erfinv(phi)*sqrt(2);
        p(n-nmutation+1:n-nmutationR,l) = z * sigma(l)+parent(n-nmutation+1:n-nmutationR,l);
        
        %-------------   ****    mutation (Random)  ****-------------
        for i=n-nmutationR+1:n
            p(i,1:var)=(valuemin(1:var)+rand(var,1).*(valuemax(1:var)...
                -valuemin(1:var)))';
        end
        for i=1:n % constraints parameters within range
          if p(i,l)<valuemin(l),    p(i,l)=valuemin(l);
          elseif p(i,l)>valuemax(l),p(i,l)=valuemax(l);
          end
        end
    end
    
    % std stopping conditions
    fval = -fvalsorted(1);
    pars =  max1(1,:); pars = pars(:)';
    iterations = iterations+1;
    funcount = n*iterations;
    
    if (fval < best_fval)
      best_fval = fval;
      best_pars = pars;
    end
  
end

% output results --------------------------------------------------------------
pars = best_pars;
fval = best_fval;

output.iterations = iterations;
output.algorithm  = options.algorithm;
output.funcCount  = funcount;



