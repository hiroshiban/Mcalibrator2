function [x,histout,costdata,itc] = bfgswopt(x0,f,tol,maxit,hess0, hdiff)
%
% C. T. Kelley, July 17, 1997
%
% This code comes with no guarantee or warranty of any kind.
%
% function [x,histout] = bfgswopt(x0,f,tol,maxit,hess0)
%
% steepest descent/bfgs with polynomial line search
% Steve Wright storage of H^-1
%
% if the BFGS update succeeds 
% backtrack on that with a polynomial line search, otherwise we use SD
%
% Input: x0 = initial iterate
%        f = objective function,
%            the calling sequence for f should be
%            [fout,gout]=f(x) where fout=f(x) is a scalar
%              and gout = grad f(x) is a COLUMN vector
%        tol = termination criterion norm(grad) < tol
%              optional, default = 1.d-6
%        maxit = maximum iterations (optional) default = 20
%         hess0 = (optional)
%            function that computes the action of the
%            initial inverse Hessian on a vector. This is optional. The
%            default is H_0 = I (ie no action). The format of hess0 is
%            h0v = hess0(v) is the action of H_0^{-1} on a vector v
%
% Output: x = solution
%         histout = iteration history   
%             Each row of histout is
%       [norm(grad), f, num step reductions, iteration count]
%         costdata = [num f, num grad, num hess] 
%                 (num hess=0 always, in here for compatibility with steep.m)
%
% At this stage all iteration parameters are hardwired in the code.
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

blow=.1; bhigh=.5;
numf=0; numg=0; numh=0;
if nargin < 4
maxit=20; 
end
if nargin < 3
tol=1.d-6;
end
itc=1; xc=x0;
maxarm=10; nsmax=50; debug=0;
%
n=length(x0);
userhess=0; 
if nargin < 5
  hess0 = [];
end
if nargin < 6
  hdiff = 1e-4;
end
if ~isempty(hess0),
  userhess=1;
end
fc = feval(f,xc); 
gc = finjac(f, fc, xc, hdiff);
numf=numf+1; numg=numg+1;
ithist=zeros(maxit,3);
ithist(1,1)=norm(gc); ithist(1,2) = fc; ithist(1,4)=itc-1;
ithist(1,3)=0; 
if debug==1
     ithist(itc,:)
end
go=zeros(n,1); 
alpha=zeros(nsmax,1); beta=alpha;
sstore=zeros(n,nsmax); ns=0;

costdata=[numf, numg, numh];
%
%	dsdp = - H_c^{-1} grad_+ if ns > 0
%
while(norm(gc) > tol & itc <= maxit)
	dsd=-gc;
	dsdp=-gc;
        if userhess==1 dsdp=feval(hess0,dsd); end
	if (ns>1)
                if userhess==1
		dsdp=bfgsw(sstore,alpha,beta,ns,dsd,hess0);
                else
		dsdp=bfgsw(sstore,alpha,beta,ns,dsd);
                end
	end
%
%
% compute the direction
%
	if (ns==0) 
		dsd=-gc;
                if userhess==1 dsd=feval(hess0,dsd); end
	else
		xi=-dsdp;
		b0=-1/(y'*s);
		zeta=(1-1/lambda)*s+xi;
		a1=b0*b0*(zeta'*y);
		a1=-b0*(1 - 1/lambda)+b0*b0*y'*xi;
		a=-(a1*s+b0*xi)'*gc;
%
%		We save go=s'*g_old just so we can use it here
%		and avoid some cancellation error
%
		alphatmp=a1+2*a/go;
		b=-b0*go;
%
%
		dsd=a*s+b*xi;
	end
%
%
%
	if (dsd'*gc > -1.d-6*norm(dsd)*norm(gc))
                % disp(' loss of descent')
                % [itc, dsd'*gc]
		dsd=-gc;
		ns=0;
	end
	lambda=1; 
%
%       fixup against insanely long steps see (3.50) in the book
%
        lambda=min(1,100/(1 + norm(gc)));
        xt=xc+lambda*dsd; ft=feval(f,xt); numf=numf+1;
	itc=itc+1; 
old=1;
if old==0 
        goal=fc+1.d-4*(gc'*dsd); iarm=0;
        if ft > goal
                 [xt,iarm,lambda]=polyline(xc,fc,gc,dsd,ft,f,maxarm);
                 if iarm==-1 x=xc; histout=ithist(1:itc,:);
                   % disp('line search failure'); 
                 return; end
        end
end
if old==1
 	iarm=0; goalval=.0001*(dsd'*gc);
 	q0=fc; qp0=gc'*dsd; lamc=lambda; qc=ft;
         while(ft > fc + lambda*goalval )
		iarm=iarm+1;
                if iarm==1
                   lambda=polymod(q0, qp0, lamc, qc, blow, bhigh);
                else
                   lambda=polymod(q0, qp0, lamc, qc, blow, bhigh, lamm, qm);
                end
                qm=qc; lamm=lamc; lamc=lambda;
		xt=xc+lambda*dsd;
		ft=feval(f,xt); qc=ft; numf=numf+1;
		if(iarm > maxarm) 
                x=xc; histout=ithist(1:itc,:);
		% disp(' too many backtracks in BFGS line search');
		return; end
	end
end
	s=xt-xc; y=gc; go=s'*gc;
%        lambda=norm(s)/norm(dsd);
	xc=xt; 
	fc = feval(f,xc); 
  gc = finjac(f, fc, xc, hdiff);
	y = gc-y; numf=numf+1; numg=numg+1;
%
%   restart if y'*s is not positive or we're out of room
%
	if (y'*s <= 0) | (ns==nsmax) 
                % disp(' loss of positivity or storage'); 
                % [ns, y'*s]
		ns=0;
	else
		ns=ns+1; sstore(:,ns)=s;
		if(ns>1)
			alpha(ns-1)=alphatmp;
			beta(ns-1)=b0/(b*lambda);
		end
	end
	ithist(itc,1)=norm(gc); ithist(itc,2) = fc; 
	ithist(itc,4)=itc-1; ithist(itc,3)=iarm;
        if debug==1
           ithist(itc,:)
	end
end
x=xc; histout=ithist(1:itc,:); costdata=[numf, numg, numh];

end
%
% bfgsw
%
% C. T. Kelley, Dec 20, 1996
%
% This code comes with no guarantee or warranty of any kind.
%
% This code is used in bfgswopt.m 
% 
% There is no reason to ever call this directly.
%
% form the product of the bfgs approximate inverse Hessian
% with a vector using the Steve Wright method
%
function dnewt=bfgsw(sstore,alpha,beta,ns,dsd,hess0)
userhess=0; if nargin==6 userhess=1; end
dnewt=dsd; 
if userhess==1 dnewt=feval(hess0,dnewt); end
if (ns<=1) return; end;
dnewt=dsd; n=length(dsd);
if userhess==1 dnewt=feval(hess0,dnewt); end
sigma=sstore(:,1:ns-1)'*dsd; gamma1=alpha(1:ns-1).*sigma;
gamma2=beta(1:ns-1).*sigma;
gamma3=gamma1+beta(1:ns-1).*(sstore(:,2:ns)'*dsd);
delta=gamma2(1:ns-2)+gamma3(2:ns-1);
dnewt=dnewt+gamma3(1)*sstore(:,1)+gamma2(ns-1)*sstore(:,ns);
if(ns <=2) return; end
dnewt=dnewt+sstore(1:n,2:ns-1)*delta(1:ns-2);
%
end

function [xp, idid, lambda]=polyline(xc, fc, gc, d, ft, f, maxarm)
%
% C. T. Kelley, Dec 29, 1997
%
% This code comes with no guarantee or warranty of any kind.
%
% function [xp, idid]=polyline(xc, fc, gc, d, ft, fobj, maxarm)
%
% polynomial line search, call after first point is rejected
%
% Input: xc = current point
%        fc = current function value
%        gc = current gradient value
%         d = direction
%        ft = trial function (rejected value)
%         f = objective function
%             the calling sequence for f should be
%             [fout,gout]=f(x) where fout=f(x) is a scalar
%             and gout = grad f(x) is a COLUMN vector
%    maxarm = maximum number of step length reductions   
%
% Output: xp = successful new point (if it exists)
%       idid = number of calls to f (if line search succeeds) or
%              -1 if line search fails.
%
% Requires: polymod.m
%
% line search parameters that everyone uses
%
alp=1.d-4; blow=.1; bhigh=.5;
%
% Set up the search
%
q0=fc; qp0=gc'*d; qc=ft; lamc=1; iarm=0; numf=0;
fgoal=fc+alp*lamc*qp0;
while ft > fgoal
    iarm=iarm+1;
    if iarm==1  % quadratic
       lambda=polymod(q0, qp0, lamc, qc, blow, bhigh);
    else
       lambda=polymod(q0, qp0, lamc, qc, blow, bhigh, lamm, qm);
    end
    qm=qc; lamm=lamc; lamc=lambda;
    xt=xc+lambda*d;
    ft=feval(f,xt); numf = numf+1; qc=ft;
    if(iarm > maxarm)
         disp(' line search failure'); idid=-1; xp=xc;
    return; end
    fgoal=fc+alp*lamc*qp0;
end
xp=xt; idid=numf;

end

% ==============================================================================

function [lplus]=polymod(q0, qp0, lamc, qc, blow, bhigh, lamm, qm)
%
% C. T. Kelley, Dec 29, 1997
%
% This code comes with no guarantee or warranty of any kind.
%
% function [lambda]=polymod(q0, qp0, qc, blow, bhigh, qm)
%
% Cubic/quadratic polynomial linesearch
%
% Finds minimizer lambda of the cubic polynomial q on the interval
% [blow * lamc, bhigh * lamc] such that
%
% q(0) = q0, q'(0) = qp0, q(lamc) = qc, q(lamm) = qm
% 
% if data for a cubic is not available (first stepsize reduction) then
% q is the quadratic such that
% 
% q(0) = q0, q'(0) = qp0, q(lamc) = qc
%
lleft=lamc*blow; lright=lamc*bhigh; 
if nargin == 6
%
% quadratic model (temp hedge in case lamc is not 1)
%
    lplus = - qp0/(2 * lamc*(qc - q0 - qp0) );
    if lplus < lleft lplus = lleft; end
    if lplus > lright lplus = lright; end
else
%
% cubic model
%
    a=[lamc^2, lamc^3; lamm^2, lamm^3];
    b=[qc; qm]-[q0 + qp0*lamc; q0 + qp0*lamm];
    if cond(a) > 1e14
            lplus = lright; 
            return
    end
    c=a\b;
    if c(2)
      lplus=(-c(1)+sqrt(c(1)*c(1) - 3 *c(2) *qp0))/(3*c(2));
    else
      lplus=Inf;
    end
    if lplus < lleft lplus = lleft; end
    if lplus > lright lplus = lright; end
end

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



end % finjac
