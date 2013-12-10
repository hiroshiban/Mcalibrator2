function [x,histout,costdata] = ntrust(x0,f,tol,maxit,resolution)
%
%
% C. T. Kelley, Dec 15, 1997
%
% This code comes with no guarantee or warranty of any kind.
%
% function [x,histout,costdata] = ntrust(x0,f,tol,maxit,resolution)
%
% Dogleg trust region, Newton model, dense algorithm 
%
% Input: x0 = initial iterate
%        f = objective function,
%            the calling sequence for f should be
%            [fout,gout]=f(x) where fout=f(x) is a scalar
%              and gout = grad f(x) is a COLUMN vector
%        tol = termination criterion norm(grad) < tol
%        maxit = maximum iterations (optional) default = 100
%        resolution = estimated accuracy in functions/gradients (optional)
%                     default = 1.d-12
%                     The finite difference increment in the difference
%                     Hessian is set to sqrt(resolution). 
%                     
%
% Output: x = solution
%         histout = iteration history   
%             Each row of histout is
%       [norm(grad), f, TR radius, iteration count] 
%         costdata = [num f, num grad, num hess] 
%
% Requires: diffhess.m, dirdero.m
%
% set maxit, the resolution, and the difference increment
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
if nargin < 4
maxit = 100;
end
if nargin < 5
resolution = 1.d-12;
end
hdiff=sqrt(resolution);
%
maxit=100; itc=1; xc=x0; n=length(x0);
fc = feval(f,xc); 
gc = finjac(f, fc, xc, hdiff);
numf=1; numg=1; numh=0;
ithist=zeros(maxit,4);
ithist(1,1)=norm(gc); ithist(1,2) = fc; ithist(1,4)=itc-1;
ithist(1,3)=0;
if debug == 1
ithist(itc,:)
end
%
% Iniitalize the TR radius, not a profound choice.

trrad=min(norm(gc),10);
%
ijob=1;
jdata=[];
while(norm(gc) > tol & itc <= maxit)
        if ijob == 1
	        hess=diffhess(xc,f,gc,hdiff);
          numf=numf+n; numg=numg+n; numh=numh+1;
        else
          jdata=sdata;
        end   
        itc=itc+1;
        [xp,newrad,idid,sdata,nf]=trfix(xc, f, hess, gc, fc, trrad,ijob,jdata);
        numf=numf+nf;
        ijob=idid;
        if idid == 2
           sdata=jdata;
        elseif idid == 3
           xpold=xp; trold=trrad; sdata=jdata;
        elseif idid == 4
           xp=xpold; newrad=trold; ijob=1; idid=1;
        end
        xc=xp; trrad=newrad;
        if idid==1
          fc = feval(f,xc); 
          gc = finjac(f, fc, xc, hdiff);
          numf=numf+1; numg=numg+1;
        end
        ithist(itc,1)=norm(gc); ithist(itc,2) = fc;
        ithist(itc,4)=itc-1; ithist(itc,3)=trrad;
if debug == 1
        ithist(itc,:)
end
end
x=xc; histout=ithist(1:itc,:);
costdata=[numf, numg, numh];

end

% ==============================================================================

function [xp, newrad,idid,sdata,nf] =...
trfix(xc, f, hc, gc, fc, oldrad,ijob,jdata)
%
%
%     C. T. Kelley, Dec 15, 1997
%
%     This code comes with no guarantee or warranty of any kind.
%
%     function [xt, newrad, idid, sdata, nf] 
%                = trfix(xc, f, hc, gc, oldrad, ijob, jdata)
%
%     Figure out what the new trust region radius and new point are
%
%     This code is called by ntrust.m
%     There is no reason for you to call this directly.
%     
%     Input: xc = current point
%     f  = objective 
%     hc = current Hessian 
%     gc = current gradient
%     fc = current function value
%     oldrad = current TR radius
%     ijob = what to do now: 1 = fresh start
%                            2 = TR radius reduction in progress
%                            3 = attempt TR radius expansion
%     jdata = Newton direction when ijob = 1 or 2, avoids recomputation
%     nf = number of function evaluations 
%
%     Output: xp = new point
%     newrad = new TR radius
%     idid = result flag: 1 = step ok
%                         2 = TR radius reduced, step not ok
%                         3 = expansion attempted, save step and try
%                             to do better
%                         4 = expansion step failed, use the last good step
%     sdata = Newton direction to use in next call if idid > 1
%
%
%     Find the Cauchy point
%
%     bflag=1 means that the trial point is on the TR boundary and is not
%             the Newton point
%
nf=0;
bflag=0;
idid=1;
trrad=oldrad;
mu=gc'*hc*gc;
mu1=gc'*gc;
dsd=-gc; 
if ijob == 1
   dnewt=hc\dsd;
else
   dnewt=jdata;
end
sdata=dnewt;
if mu > 0
   sigma = mu1/mu;
   if(sigma*norm(gc)) > trrad
      sigma=trrad/norm(gc);
   end
   cp = xc-sigma*gc;
else
%
%     If steepest descent direction is a direction of negative curvature
%     take a flying leap to the boundary.
%
   bflag=1;
   sigma=trrad/norm(gc);
   cp=xc-sigma*gc;
end
%
%     If CP is on the TR boundary, that's the trial point.
%     If it's not, compute the Newton point and complete the dogleg.
%
if bflag==1
   xt=cp;
else
%
%     If we get to this point, CP is in the interior and the steepest
%     descent direction is a direction of positive curvature.
%
   dsd=-gc; dnewt=hc\dsd;
   xn=xc+dnewt;
   mu2=dsd'*dnewt;
%
%     If the Newton direction goes uphill, revert to CP.
%
   if mu2 <= 0
       xt=cp;
%
%     If the Newton point is inside, take it.
%
   elseif norm(dnewt) <= trrad
       xt=xn;
%
%    Newton is outside and CP is inside. Find the intersection of the
%    dog leg path with TR boundary.
%
   else
       d1=sigma*gc; d2=d1+dnewt;
       aco=d2'*d2; bco=-2*d1'*d2; cco= (d1'*d1) - trrad*trrad;
       xi=(-bco+sqrt((bco*bco) - 4*aco*cco))/(2*aco);
       xt=cp + xi*(xn-cp);
       bflag=1;
   end
end
%
%     Now adjust the TR radius using the trial point
%
st=xt-xc; ft=feval(f,xt); ared=ft-fc; nf=nf+1;
pred=gc'*st + .5* (st'*hc*st);
if ared/pred < .25
   xt=xc;
   trrad=norm(st)*.5;
   idid=2;
   if ijob == 3 idid = 4; end
elseif ared/pred > .75 & bflag==1
   trrad=trrad*2;
   idid=3;
end
newrad=trrad;
xp=xt;

end

function hess = diffhess(x, f, gc, heps)
% compute a forward difference Hessian f''(x)
%
% uses dirdero.m to compute the columns, then symmetrize
%
% C. T. Kelley, March 17, 1998
%
% This code comes with no guarantee or warranty of any kind.
%
%
% Inputs:       x, f = point and function
%	        gc = current gradient, preevaluated
%		heps = difference increment (optional)
%                        default = 1.d-6
%		
%		the calling sequence for the function is
%		[func,grad]=f(x)
%
% Output: 	hess = hessian
%
if nargin == 3
heps = 1.d-6;
end
n=length(x);
for j=1:n
    zz=zeros(n,1);
    zz(j)=1;
    hess(:,j)=dirdero(x,zz,f,gc,heps);
end
%
% symmetrize
%
hess=(hess+hess')*.5;

end

% ==============================================================================
function z = dirdero(x,w,f,gc,epsnew)
% Finite difference directional derivative for optimization
% Approximate f''(x) w
% 
% C. T. Kelley, Dec 20, 1996
%
% This code comes with no guarantee or warranty of any kind.
%
% function z = dirdero(x,w,f,gc,epsnew)
%
% Inputs:
%           x, w = point and direction
%           f = function, the calling sequence is
%				[fun,grad]=f(x)
%           gc = current gradient
%                gc has usually been computed
%                before the call to dirdero
%           epsnew = difference increment (optional)
%                    default = 1.d-6
% 
% Output:   directional derivative  
%
% used in : ntrust, cgtrust
% uses:     dirdero, gradest
if nargin == 4
epsnew=1e-6;
end
%
n=length(x);
%
% scale the step
%
if norm(w) == 0
    z=zeros(n,1);
return
end
epsnew = epsnew/norm(w);
%
% del and g1 could share the same space if storage
% is more important than clarity
%
del=x+epsnew*w;
f1=feval(f,del);
g1 = finjac(f, f1, del, epsnew); g1=reshape(g1, size(x));
z = (g1 - gc)/epsnew;

end

%   FINJAC       numerical approximation to Jacobi matrix
%   %%%%%%
function J = finjac(FUN,r,x,epsx)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% pars=column, function=row vector or scalar
  lx=length(x);
  J=zeros(lx,length(r));
  if size(x,2) > 1, x=x'; end % column
  if size(r,1) > 1, r=r'; end % row
  if numel(epsx)==1, epsx=epsx*max(abs(x),1); end
  if any(epsx == 0), epsx(find(~epsx)) = 1e-4; end
  for k=1:lx
      dx=.25*epsx(k);
      xd=x;
      xd(k)=xd(k)+dx;
      rd=feval(FUN,xd);
      if size(rd,1) > 1, rd=rd'; end % row
  %   ~~~~~~~~~~~~~~~~    
      if dx, J(k,:)=((rd-r)/dx); end
  end
end

