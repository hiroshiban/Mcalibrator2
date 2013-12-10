function [pars,fval,itc,output] = imfil1(x0,f,options)
%
%
% C. T. Kelley, January 9, 1998
%
% This code comes with no guarantee or warranty of any kind.
%
% function [x,fcount,histout] = imfil(x0,f,budget,scales,parms)
%
% Unconstrained implicit filtering code
% 
% IMPLICIT FILTERING with SR1 and BFGS quasi-Newton methods
%
% Input: x0 = initial iterate
%        f = objective function,
%            the calling sequence for f should be [fout]=f(x)
%        budget = max f evals 
%                 The iteration will terminate after the iteration that
%                 exhausts the budget, default=50*number of variables
%        scales = the decreasing sequence of difference increments 
%                 This is an optional argument and the default is
%                 1, 1/2, ... 1/128
%        parms = optional argument = array of conrol praamters
%
%        parms(1) = 
%             target = value of f at which the iteration should be terminated
%                 This is an optional argument, which you SHOULD set to
%                 something reasonable for your problem. The default is
%                 as close to no limit as we can get, -1.d8
%
%        parms(2) = 0 for centered diffs, 1 for forward diffs
%                   default and recommended value = 0
% 
%        parms(3) = quasi-Newton method selection
%                   0 = none, 1 = bfgs, 2 = SR1
%                   default and recommend value = 1
%
%
% Output: x = estimated minimizer
%         lhist = number of nonzero rows in histout 
%               = number of nonlinear iterations for all the scales        
%         histout = iteration history, updated after each nonlinear iteration 
%                 = lhist x 5 array, the rows are
%                   [fcount, fval, norm(sgrad), norm(step), iarm]
%                   fcount = cumulative function evals
%                   fval = current function value
%                   norm(sgrad) = current simplex grad norm
%                   norm(step) = norm of last step 
%                   iarm=line searches to date
%                        =-1 means first iterate at a new scale 
%
% This code uses centered difference approximations to the gradient. Setting
% fdiff = 1 will change this to forward differences. We do not recommend 
% that.
%
% set debug = 1 to print iteration stats
%

%  These M-files are implementations of the algorithms from the book
%  "Iterative Methods for Optimization", to be published by SIAM,
%  by C. T. Kelley. The book, which describes the algorithms, is available
%  from SIAM (service@siam.org). These files can be modified for non-commercial
%  purposes provided that the authors: 
%
%  C. T. Kelley for all MATLAB codes, 
%  P. Gilmore and T. D. Choi for iffco.f
%  J. M. Gablonsky for DIRECT
%
%  are acknowledged and clear comment lines are inserted
%  that the code has been changed. The authors assume no no responsibility
%  for any errors that may exist in these routines.

debug=0;
%
fcount=0; 
%
% And now for the knobs. Implicit filtering has too many of these and they
% can make a difference. The ones we use are:
%
% min_gscal (default = .01)
%   if norm(difference_grad) < min_gscal*h  we terminate at the scale
%   with success
%
% maxit and maxitarm (defaults 2 and 5)
%    At most maxit*n iterations are taken for each scale and at most
%    maxitarm step length reductions are allowed
%
% nterm controls termination on stencil failure for centered diffs (defalt = 0)
%       = 0 to terminate on stencil failure before starting the line search
%       = 1 to ignore stencil failure
%
% iquit (default = 3)
%    After iquit consecutive line search failures, we terminate the iteration
%
% beta (default = .5) 
%    step size reduction factor in the line search
%
% set the knobs
%
% min_gscal=.5; 
min_gscal=.01; 
% maxit=10; maxitarm=10; iquit=3; beta=.1;
maxit=options.MaxIter; 
maxitarm=10; iquit=3; beta=.5; nterm=0;

switch lower(options.Hybrid)
case 'sr1'
  quasi=2;
case 'none'
  quasi=0;
case 'bfgs'
  quasi=1;
otherwise % BFGS
  quasi=1;
end

flim=options.MaxFunEvals;
%
% set up the difference scales
%
quasi=1; fdiff=0;
ftol=options.TolFun;
nterm=fdiff+nterm;

dscal=-(0:maxit)'; dscal=2.^dscal;

nscal=length(dscal);
n=length(x0);
%
% sweep through the scales
%
x=x0; xold=x0; n=length(x0); v=eye(n); xc=x0; hess=eye(n); ns=0; iquitc=0;
iterations=0;

% for ns=1:nscal
while (ns < nscal & fcount <= flim & iquitc < iquit)
  ns=ns+1;
  itc=0; h=dscal(ns); z0=x; fval=feval(f,x); fcount=fcount+1;
  if ns == 1
    best_pars = x;
    best_fval = fval;
  end
  pars_prev=x;
  fval_prev=fval;
  stol=min_gscal*h; iarm=0; lok=1;
  [sgrad,fb,xb,sflag] =simpgrad(x,f,h*v,fval,fdiff);
  fcount=fcount+(2-fdiff)*n; 
  if norm(sgrad,inf) < stol | (sflag+nterm)==0
%
%   Convergence at this scale on stencil failure or tolerance match
%
    gc=sgrad;
    if (sflag+nterm) ~= 0 
       iquitc=iquitc+1; 
    else
       iquitc=0;
    end
    iterations=iterations+1;
  else
%
%   Take a few quasi-Newton iterates
%
    iquitc=0;
    while itc < maxit*n & fval > ftol & norm(sgrad,inf) >= stol...
        &lok==1 & fcount < flim & sflag+nterm > 0
      itc=itc+1;
      iterations=iterations+1;
%
%     compute the difference gradient, scale it
%
      gc=sgrad; 
      if(itc > 1)
        [sgrad,fb,xb,sflag]=simpgrad(x,f,h*v,fval,fdiff); 
        fcount=fcount+(2-fdiff)*n; 
      end
      dgrad=sgrad;
%
%     watch out for stencil failure!
%
      if sflag+nterm > 0
%
%     update iterate and Hessian 
%
        if itc > 1 & quasi > 0
          if quasi==1
             hess = bfupdate(x, xc, sgrad, gc, hess); 
          else
            hess = sr1up(x, xc, sgrad, gc, hess); 
          end
        end; 
        xc=x;
%
%     new direction and line search
%
        if quasi > 0
          if cond(hess) < 1e8, sdir=hess\dgrad; % WARN: hess\dgrad can be singular
          else sdir = pinv(hess)*dgrad;
          end
        else
          sdir=dgrad;
        end
        [fct, x, fval, hess, iarm]=...
              linearm(f, sdir, fval, x, hess, maxitarm,beta,h,quasi,fdiff);
        fcount=fcount+fct;
%
%     reduce scale upon failure of line search
%
        if iarm >= maxitarm
           lok=0;
           x=xb; fval=fb;
        end
      end
%
%      keep the records
%
      stepn=norm(xold-x,inf); xold=x;
%
    end % end of nonlinear step
%
  end % end of sweep through the scale
  pars=x;
  
  if (fval < best_fval)
    best_fval = fval;
    best_pars = pars;
  end
end % end of while loop over the scales

% output results --------------------------------------------------------------
pars = best_pars;
fval = best_fval;

output.iterations = iterations;
output.algorithm  = options.algorithm;
output.funcCount  = fcount;

end
% end main imfil

% ==============================================================================
%
%   BFGS update of Hessian; nothing fancy
%
function hess = bfupdate(x, xc, sgrad, gc, hess)
y=sgrad-gc; s=x-xc; z=hess*s;
if y'*s > 0
   hess = hess + (y*y'/(y'*s)) - (z*z'/(s'*z));
end

end
%
% SR1 update
%
function hess = sr1up(x, xc, sgrad, gc, hess)
y=sgrad-gc; s=x-xc; z=y - hess*s;
if z'*s ~=0
	ptst=z'*(hess*z)+(z'*z)*(z'*z)/(z'*s); 
	if ptst > 0 hess = hess + (z*z')/(z'*s); end
end

end

% ==============================================================================

%
%    Line search for implicit filtering
%
function [fct, x, fval, hessp, iarm]=...
                linearm(f, sdir, fold, xc, hess, maxitarm,beta,h,quasi,fdiff)
lambda=1;
n=length(xc);
hessp=hess;
iarm=-1;
fct=0;
aflag=1;
dd=sdir;
smax=10*min(h,1); if norm(dd) > smax dd=smax*dd/norm(dd); end
x=xc;
fval=fold;
while iarm < maxitarm & aflag==1
    d=-lambda*dd; 
    iarm=iarm+1;
    xt=x+d; ft=feval(f,xt); fct=fct+1;
    if ft < fval & aflag==1; aflag=0; fval=ft; x=xt; end
    if aflag==1; lambda=beta*lambda; end
end
if iarm == maxitarm & aflag == 1
       % disp(' line search failure'); [iarm, h, quasi, fdiff]
%      hessp=eye(n);
end

end

% ==============================================================================

function [sgr,fb,xb,sflag]=simpgrad(x,f,v,fc,fdiff)
%
% simplex gradient for use with implicit filtering
% also tests for best point in stencil
%
% set fdiff = 1 to get forward differencing, useful in Nelder-Mead
%               simplex condition/gradient computaiton
%
% omit fdiff or set to 0 in typical implicit filtering mode
%
%   compute the simplex gradient
%
%   Output: sgr = simplex gradient
%           fb  = best value in stencil
%           xb  = best point in stencil
%           sflag = 0 if (1) you're using central diffs and 
%                        (2) center of stencil is best point
%           sflag is used to detect stencil failure
%         
%
n=length(x); delp=zeros(n,1); delm=zeros(n,1);
xb=x; fb=fc; sflag=0;
for j=1:n;
   xp=x+v(:,j); xm=x-v(:,j); fp=feval(f,xp); delp(j)=fp-fc;
   if fp < fb fb=fp; xb=xp; sflag=1; end
   if fdiff==0 fm=feval(f,xm); delm(j)=fc-fm; 
      if fm < fb fb=fm; xb=xm; sflag=1; end
   end;
end
if fdiff==1 
   sgr=v'\delp; 
else
   sgr=.5*((v'\delp)+(v'\delm));
end
if fdiff==1
    xb=x; fb=fc; sflag=1;
end
 end
