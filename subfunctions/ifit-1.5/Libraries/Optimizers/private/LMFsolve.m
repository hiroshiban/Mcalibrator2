function [xf, S, nfJ,exitflag] = LMFsolve(varargin)
% Solve a Set of Overdetermined Nonlinear Equations in Least-Squares Sense.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A solution is obtained by a Fletcher version of the Levenberg-Maquardt 
% algoritm for minimization of a sum of squares of equation residuals. 
%
% [Xf, Ssq, Cnt, exitflag] = LMFsolve(FUN,Xo,Options)
% FUN     is a function handle or a function M-file name that evaluates
%         m-vector of equation residuals,
% Xo      is n-vector of initial guesses of solution,
% Options is an optional set of Name/Value pairs of control parameters 
%         of the algorithm. It may be also preset by calling:
%         Options = LMFsolve('default'), or by a set of Name/Value pairs:
%         Options = LMFsolve('Name',Value, ... ), or updating the Options
%                   set by calling
%         Options = LMFsolve(Options,'Name',Value, ...).
%
%    Name   Values {default}         Description
% 'Display'     integer     Display iteration information
%                            {0}  no display
%                             k   display initial and every k-th iteration;
% 'Jacobian'    handle      Jacobian matrix function handle; {@finjac}
% 'FunTol'      {1e-7}      norm(FUN(x),1) stopping tolerance;
% 'XTol'        {1e-7}      norm(x-xold,1) stopping tolerance;
% 'MaxIter'     {100}       Maximum number of iterations;
% 'ScaleD'                  Scale control:
%               value        D = eye(m)*value;
%               vector       D = diag(vector);
%                {[]}        D(k,k) = JJ(k,k) for JJ(k,k)>0, or
%                                   = 1 otherwise,
%                                     where JJ = J.'*J
% Not defined fields of the Options structure are filled by default values.
%
% Output Arguments:
% Xf        final solution approximation
% Ssq       sum of squares of residuals
% Cnt       count of function calls
% exitflag  indicates final status of optimization

% Example:
% The general Rosenbrock's function has the form
%    f(x) = 100(x(1)-x(2)^2)^2 + (1-x(1))^2
% Optimum solution gives f(x)=0 for x(1)=x(2)=1. Function f(x) can be 
% expressed in the form 
%    f(x) = f1(x)^2 =f2(x)^2,
% where f1(x) = 10(x(1)-x(2)^2) and f2(x) = 1-x(1).
% Values of the functions f1(x) and f2(x) can be used as residuals.
% LMFsolve finds the solution of this problem in 5 iterations. The more 
% complicated problem sounds:
% Find the least squares solution of the Rosenbrock valey inside a circle 
% of the unit diameter centered at the origin. It is necessary to build 
% third function, which is zero inside the circle and increasing outside it. 
% This property has, say, the next function:
%    f3(x) = sqrt(x(1)^2 + x(2)^2) - r, where r is a radius of the circle.
% Its implementation using anonymous functions has the form
%    R  = @(x) sqrt(x'*x)-.5;    %   A distance from the radius r=0.5
%    ros= @(x) [10*(x(2)-x(1)^2); 1-x(1); (R(x)>0)*R(x)*1000];
%    [x,ssq,cnt]=LMFsolve(ros,[-1.2,1],'Display',1,'MaxIter',50)
% Solution: x = [0.4556; 0.2059],  |x| = 0.5000
% sum of squares: ssq = 0.2966,  
% number of iterations: cnt = 18.
%
% Note:   
% Users with older MATLAB versions, which have no anonymous functions
% implemented, have to call LMFsolve with named function for residuals. 
% For above example it is
%
%   [x,ssq,cnt]=LMFsolve('rosen',[-1.2,1]);
%
% where the function rosen.m is of the form
%
%   function r = rosen(x)
%%  Rosenbrock valey with a constraint
%   R = sqrt(x(1)^2+x(2)^2)-.5;
%%  Residuals:
%   r = [ 10*(x(2)-x(1)^2)  %   first part
%         1-x(1)            %   second part
%         (R>0)*R*1000.     %   penalty
%       ];

% Reference:
% Fletcher, R., (1971): A Modified Marquardt Subroutine for Nonlinear Least
% Squares. Rpt. AERE-R 6799, Harwell

% Miroslav Balda, 
% balda AT cdm DOT cas DOT cz
% 2007-07-02    v 1.0
% 2008-12-22    v 1.1 * Changed name of the function in LMFsolv
%                     * Removed part with wrong code for use of analytical 
%                       form for assembling of Jacobian matrix
% 2009-01-08    v 1.2 * Changed subfunction printit.m for better one, and
%                       modified its calling from inside LMFsolve.
%                     * Repaired a bug, which caused an inclination to
%                       istability, in charge of slower convergence.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%  Copyright (c) 2007, Miroslav Balda
%  All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are
%  met:
%
%      * Redistributions of source code must retain the above copyright
%        notice, this list of conditions and the following disclaimer.
%      * Redistributions in binary form must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in
%        the documentation and/or other materials provided with the distribution
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%  POSSIBILITY OF SUCH DAMAGE.

%   OPTIONS
    %%%%%%%
%               Default Options
if nargin==1 && strcmpi('default',varargin(1))
   xf.Display  = 0;         %   no print of iterations
   xf.Jacobian = @finjac;   %   finite difference Jacobian approximation
   xf.MaxIter  = 100;       %   maximum number of iterations allowed
   xf.ScaleD   = [];        %   automatic scaling by D = diag(diag(J'*J))
   xf.FunTol   = 1e-6;      %   tolerace for final function value
   xf.XTol     = 1e-4;      %   tolerance on difference of x-solutions
   xf.Evals    = 1000;
   return
   
%               Updating Options
elseif isstruct(varargin{1}) % Options=LMFsolve(Options,'Name','Value',...)
    if ~isfield(varargin{1},'Jacobian')
        error('Options Structure not Correct for LMFsolve.')
    end
    xf=varargin{1};          %   Options
    for i=2:2:nargin-1
        name=varargin{i};     %   option to be updated
        if ~ischar(name)
            error('Parameter Names Must be Strings.')
        end
        name=lower(name(isletter(name)));
        value=varargin{i+1};  %   value of the option  
        if strncmp(name,'d',1), xf.Display  = value;
        elseif strncmp(name,'f',1), xf.FunTol   = value(1);
        elseif strncmp(name,'x',1), xf.XTol     = value(1);
        elseif strncmp(name,'j',1), xf.Jacobian = value;
        elseif strncmp(name,'m',1), xf.MaxIter  = value(1);
        elseif strncmp(name,'s',1), xf.ScaleD   = value;
        elseif strncmp(name,'e',1), xf.Evals    = value(1);
        else   disp(['Unknown Parameter Name --> ' name])
        end
    end
    return
   
%               Pairs of Options     
elseif ischar(varargin{1})  % check for Options=LMFsolve('Name',Value,...)
   Pnames=char('display','funtol','xtol','jacobian','maxiter','scaled');
   if strncmpi(varargin{1},Pnames,length(varargin{1}))
      xf=LMFsolve('default');  % get default values
      xf=LMFsolve(xf,varargin{:});
      return
   end
end

%   LMFsolve(FUN,Xo,Options)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%

FUN=varargin{1};            %   function handle
if ~(isvarname(FUN) || isa(FUN,'function_handle'))
   error('FUN Must be a Function Handle or M-file Name.')
end

xc=varargin{2};             %   Xo

if nargin>2                 %   OPTIONS
    if isstruct(varargin{3})
        options=varargin{3};
    else
        if ~exist('options','var')
            options = LMFsolve('default');
        end
        for i=3:2:size(varargin,2)-1
            options=LMFsolve(options, varargin{i},varargin{i+1});
        end
    end
else
    if ~exist('options','var')
        options = LMFsolve('default');
    end
end

x=xc(:);
lx=length(x);

r=sqrt(feval(FUN,x));             % Residuals at starting point
if length(r) == 1, r=r*ones(5,1)/5; 
else r=r(:); end
%~~~~~~~~~~~~~~
S=r'*r;
epsx=options.XTol(:);
J=options.Jacobian(FUN,r,x,epsx);
nfJ = lx+1;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
A=J.'*J;                    % System matrix
v=J.'*r;

D = options.ScaleD;
if isempty(D)
    D=diag(diag(A));        % automatic scaling
    for i=1:lx
        if D(i,i)==0, D(i,i)=1; end
    end
else
    if numel(D)>1
        D=diag(sqrt(abs(D(1:lx)))); % vector of individual scaling
    else
        D=sqrt(abs(D))*eye(lx);     % scalar of unique scaling
    end
end

Rlo=0.25; Rhi=0.75;
l=1;      lc=.75;     is=0;
cnt=0;
d=options.XTol;             %   vector for the first cycle

exitflag=0;

while exitflag==0      %   MAIN ITERATION CYCLE
    try
    d=pinv(A+l*D)*v;
    catch
    d=(A+l*D)\v;            % negative solution increment
    end
    xd=x-d;
    rd=sqrt(feval(FUN,xd)); 
    if length(rd) == 1, rd=rd*ones(5,1)/5; 
    else rd=rd(:); end
    nfJ = nfJ+1;
%   ~~~~~~~~~~~~~~~~~    
    Sd=rd.'*rd;
    dS=d.'*(2*v-A*d);       % predicted reduction
    R=(S-Sd)/dS;

    if R>Rhi
        l=l/2;
        if l<lc, l=0; end
    elseif R<Rlo
        nu=(Sd-S)/(d.'*v)+2;
        if nu<2
            nu=2;
        elseif nu>10
            nu=10;
        end
        if l==0
            lc=1/max(abs(diag(pinv(A))));
            l=lc;
            nu=nu/2;
        end
        l=nu*l;
    end
    cnt=cnt+1;

    S=Sd; x=xd; r=rd;
    J=options.Jacobian(FUN,r,x,epsx);
    nfJ = nfJ+lx;
%       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    A=J.'*J;   v=J.'*r;

    
    if      cnt>=options.MaxIter       exitflag=-2; % max iteration reached
    elseif  all(abs(d)<options.XTol/1000)   exitflag=-1; % parameter change increment is negligible
    elseif  all(abs(r)<options.FunTol) exitflag=-5; % function change increment reached
    elseif  nfJ > options.Evals,       exitflag=-3; % max nb function evaluations reached
    end
end
xf = x;                         %   final solution

end

%   FINJAC       numerical approximation to Jacobi matrix
%   %%%%%%
function J = finjac(FUN,r,x,epsx)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% pars=column, function=row vector or scalar
  lx=length(x);
  J=zeros(length(r), lx);
  x=x(:)';
  r=r(:);
  if numel(epsx)==1, epsx=epsx*max(abs(x),1); end
  if any(epsx == 0), epsx(find(~epsx)) = 1e-4; end
  epsx=epsx(:)';
  for k=1:lx
      dx=.25*epsx(k);
      xd=x;
      xd(k)=xd(k)+dx;
      rd=sqrt(feval(FUN,xd));
      if length(rd) == 1, rd=rd*ones(5,1)/5; 
      else rd=rd(:); end
  %   ~~~~~~~~~~~~~~~~    
      if dx, J(:,k)=((rd-r)/dx); end
  end
end % finjac

