function [pars,fval,istop,output]=powell(S,x0,options)
%   Unconstrained optimization using Powell.
%
%   [xo,Ot,nS]=powell(S,x0,ip,method,Lb,Ub,problem,tol,mxit)
%
%   S: objective function
%   x0: initial point
%   ip: (0): no plot (default), (>0) plot figure ip with pause, (<0) plot figure ip
%   method: (0) Coggins (default), (1): Golden Section
%   Lb, Ub: lower and upper bound vectors to plot (default = x0*(1+/-2))
%   problem: (-1): minimum (default), (1): maximum
%   tol: tolerance (default = 1e-4)
%   mxit: maximum number of stages (default = 50*(1+4*~(ip>0)))
%   xo: optimal point
%   Ot: optimal value of S
%   nS: number of objective function evaluations

%   Copyright (c) 2001 by LASIM-DEQUI-UFRGS
%   $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
%   Argimiro R. Secchi (arge@enq.ufrgs.br)

mxit=options.MaxIter;
tol =options.TolFun;
problem=-1;
if strcmp(lower(options.Hybrid), 'golden')
  method=1;
else method=0; end
istop=0;

% original code
x0=x0(:); pars=x0; fval = feval(S,x0);
y0=fval*problem;
n=size(x0,1);
D=eye(n);

xo=x0;
yo=y0;
it=0;
nS=1;

best_pars = pars;
best_fval = fval;

while it < mxit,
                   % exploration
  xo_prev=pars;
  yo_prev=fval;
  delta=0;
  k=1;
  for i=1:n,
    if method,           % to see the linesearch plot, remove the two 0* below
     [stepsize,x,Ot,nS1]=aurea(S,xo,D(:,i),problem,tol,mxit);
     Ot=Ot*problem;
    else
     [stepsize,x,Ot,nS1]=coggins(S,xo,D(:,i),problem,tol,mxit);
     Ot=Ot*problem;
    end

    nS=nS+nS1;
    di=Ot-yo;
    if di > delta,
     delta=di;
     k=i;
    end

    yo=Ot;
    xo=x;
  end
                % progression
  it=it+1;
  xo=2*x-x0; fval=feval(S,xo); pars=xo;
  Ot=fval*problem;
  nS=nS+1;
  di=y0-Ot;

  j=0;
  if di >= 0 | 2*(y0-2*yo+Ot)*((y0-yo-delta)/di)^2 >= delta,
    if Ot >= yo,
      yo=Ot;
    else
      xo=x;
      j=1;
    end
  else
    if k < n,
      D(:,k:n-1)=D(:,k+1:n);
    end
    D(:,n)=(x-x0)/norm2(x-x0);
    if method,           % to see the linesearch plot, remove the two 0* below
      [stepsize,xo,yo,nS1,it1]=aurea(S,x,D(:,n),problem,tol,mxit);
      yo=yo*problem;
    else
      [stepsize,xo,yo,nS1,it1]=coggins(S,x,D(:,n),problem,tol,mxit);
      yo=yo*problem;
    end
   if it1 == mxit & (strcmp(options.Display,'iter') | strcmp(options.Display,'notify'))
     disp([ 'Warning Powell/Line search: reached maximum number of iterations (' num2str(mxit) ')' ]);
   end
     
    nS=nS+nS1;
  end

  if norm2(xo-x0) < tol*(0.1+norm2(x0)) & abs(yo-y0) < tol*(0.1+abs(y0)),
    istop=-1;
    message='Converged: Termination function tolerance criteria reached';
    break;
  end
    
  if (fval < best_fval)
    best_fval = fval;
    best_pars = pars;
  end

  if istop
    break
  end
  
  y0=yo;
  x0=xo;
end % while

% output results --------------------------------------------------------------
pars = best_pars;
fval = best_fval;

if istop==0, message='Algorithm terminated normally'; end
output.iterations = it;
output.algorithm  = options.algorithm;
output.message    = message;
output.funcCount  = nS;

 
 % PRIVATE functions ----------------------------------------------------------
 function [stepsize,xo,Ot,nS,it]=aurea(S,x0,d,problem,tol,mxit,stp)
%   Performs line search procedure for unconstrained optimization
%   using golden section.
%
%   [stepsize,xo,Ot,nS]=aurea(S,x0,d,ip,problem,tol,mxit,stp)
%
%   S: objective function
%   x0: initial point
%   d: search direction vector
%   ip: (0): no plot (default), (>0) plot figure ip with pause, (<0) plot figure ip
%   problem: (-1): minimum (default), (1): maximum
%   tol: tolerance (default = 1e-4)
%   mxit: maximum number of iterations (default = 50*(1+4*~(ip>0)))
%   stp: initial stepsize (default = 0.01*sqrt(d'*d))
%   stepsize: optimal stepsize
%   xo: optimal point in the search direction
%   Ot: optimal value of S in the search direction
%   nS: number of objective function evaluations

%   Copyright (c) 2001 by LASIM-DEQUI-UFRGS
%   $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
%   Argimiro R. Secchi (arge@enq.ufrgs.br)

 if nargin < 3,
   error('aurea requires three input arguments');
 end
 if nargin < 4 | isempty(problem),
   problem=-1;
 end
 if nargin < 5 | isempty(tol),
   tol=1e-4;
 end
 if nargin < 6 | isempty(mxit),
   mxit=200;
 end

 d=d(:);
 nd=d'*d;

 if nargin < 7 | isempty(stp),
   stepsize=0.01*sqrt(nd);
 else
   stepsize=abs(stp);
 end

 x0=x0(:);
 [x1,x2,nS]=bracket(S,x0,d,problem,stepsize);
 z(1)=d'*(x1-x0)/nd;
 z(2)=d'*(x2-x0)/nd;

 fi=.618033985;
 k=0;
 secao=fi*(z(2)-z(1));
 p(1)=z(1)+secao;
 x=x0+p(1)*d;
 y(1)=feval(S,x)*problem;
 p(2)=z(2)-secao;
 x=x0+p(2)*d;
 y(2)=feval(S,x)*problem;
 nS=nS+2;
 
 it=0;
 while abs(secao/fi) > tol & it < mxit,
   if y(2) < y(1),
     j=2; k=1;
   else
     j=1; k=2;
   end
   
   z(k)=p(j);
   p(j)=p(k);
   y(j)=y(k);
   secao=fi*(z(2)-z(1));
   p(k)=z(k)+(j-k)*secao;
   x=x0+p(k)*d;
   y(k)=feval(S,x)*problem;
   nS=nS+1;

   it=it+1;
 end

 stepsize=p(k);
 xo=x; 
 Ot=y(k)*problem;  

% -----------------------------------------------------------------------------
function [stepsize,xo,Ot,nS,it]=coggins(S,x0,d,problem,tol,mxit,stp)
%   Performs line search procedure for unconstrained optimization
%   using quadratic interpolation.
%
%   [stepsize,xo,Ot,nS]=coggins(S,x0,d,ip,problem,tol,mxit)
%
%   S: objective function
%   x0: initial point
%   d: search direction vector
%   ip: (0): no plot (default), (>0) plot figure ip with pause, (<0) plot figure ip
%   problem: (-1): minimum (default), (1): maximum
%   tol: tolerance (default = 1e-4)
%   mxit: maximum number of iterations (default = 50*(1+4*~(ip>0)))
%   stp: initial stepsize (default = 0.01*sqrt(d'*d))
%   stepsize: optimal stepsize
%   xo: optimal point in the search direction
%   Ot: optimal value of S in the search direction
%   nS: number of objective function evaluations

%   Copyright (c) 2001 by LASIM-DEQUI-UFRGS
%   $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
%   Argimiro R. Secchi (arge@enq.ufrgs.br)
 
 if nargin < 3,
   error('coggins requires three input arguments');
 end
 if nargin < 4 | isempty(problem),
   problem=-1;
 end
 if nargin < 5 | isempty(tol),
   tol=1e-4;
 end
 if nargin < 6 | isempty(mxit),
   mxit=200;
 end

 d=d(:);
 nd=d'*d;

 if nargin < 8 | isempty(stp),
   stepsize=0.01*sqrt(nd);
 else
   stepsize=abs(stp);
 end

 x0=x0(:);
 [x1,x2,nS]=bracket(S,x0,d,problem,stepsize);
 z(1)=d'*(x1-x0)/nd;
 y(1)=feval(S,x1)*problem;
 z(3)=d'*(x2-x0)/nd;
 y(3)=feval(S,x2)*problem;
 z(2)=0.5*(z(3)+z(1));
 x=x0+z(2)*d;
 y(2)=feval(S,x)*problem;
 nS=nS+3;
 
 it=0;
 while it < mxit,
   a1=z(2)-z(3); a2=z(3)-z(1); a3=z(1)-z(2);
   if y(1)==y(2) & y(2)==y(3),
     zo=z(2);
     x=x0+zo*d;
     ym=y(2);
   else
     zo=.5*(a1*(z(2)+z(3))*y(1)+a2*(z(3)+z(1))*y(2)+a3*(z(1)+z(2))*y(3))/ ...
        (a1*y(1)+a2*y(2)+a3*y(3));
     if any(isnan(zo)), zo=z(2); end
     x=x0+zo*d;
     ym=feval(S,x)*problem;
     nS=nS+1;
   end

   for j=1:3,
    if abs(z(j)-zo) < tol*(0.1+abs(zo)),
      stepsize=zo;
      xo=x;
      Ot=ym*problem;
      return;
    end
   end

   if (z(3)-zo)*(zo-z(2)) > 0,
     j=1;
   else
     j=3;
   end
    
   if ym > y(2),
     z(j)=z(2);
     y(j)=y(2);
     j=2;
   end
    
   y(4-j)=ym;
   z(4-j)=zo;
   it=it+1;
 end

 stepsize=zo;
 xo=x;
 Ot=ym*problem;

% -----------------------------------------------------------------------------

function [x1,x2,nS]=bracket(S,x0,d,problem,stepsize)
%   Bracket the minimum (or maximum) of the objective function
%   in the search direction.
%
%   [x1,x2,nS]=bracket(S,x0,d,problem,stepsize)
%
%   S: objective function
%   x0: initial point
%   d: search direction vector
%   problem: (-1): minimum (default), (1): maximum
%   stepsize: initial stepsize (default = 0.01*norm(d))
%   [x1,x2]: unsorted lower and upper limits
%   nS: number of objective function evaluations

%   Copyright (c) 2001 by LASIM-DEQUI-UFRGS
%   $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
%   Argimiro R. Secchi (arge@enq.ufrgs.br)

 if nargin < 3,
   error('bracket requires three input arguments');
 end
 if nargin < 4,
   problem=-1;
 end
 if nargin < 5,
   stepsize=0.01*norm2(d);
 end

 d=d(:);
 x0=x0(:);
 j=0; nS=1;
 y0=feval(S,x0)*problem;
 
 while j < 2,
  x=x0+stepsize*d;
  y=feval(S,x)*problem;
  nS=nS+1;
  
  if y0 >= y,
    stepsize=-stepsize;
    j=j+1;
  else
    while y0 < y,
      stepsize=2*stepsize;
      y0=y;
      x=x+stepsize*d;
      y=feval(S,x)*problem;
      nS=nS+1;
    end  
    j=1;
    break;
  end
 end
 
 x2=x;
 x1=x0+stepsize*(j-1)*d;
% -----------------------------------------------------------------------------
function n=norm2(x)
x = x(:);
n=sqrt(sum(abs(x).*abs(x)));

