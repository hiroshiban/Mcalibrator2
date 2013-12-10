function [x,e, itc]=ukfopt(h,x,tol,P,Q,R,maxit)
%UKFOPT     Unconstrained optimization using the unscented Kalman filter
%
%       [x,e]=ukfopt(f,x,tol,P,Q,R) minimizes e=norm(f(x)) until e<tol. P, Q
%       and R are tuning parmeters relating to the Kalman filter
%       performance. P and Q should be n x n, where n is the number of 
%       decision variables, while R should be m x m, where m is the 
%       dimension of f. Normally, Q and R should be set to d*I e*I where 
%       both d and e are vary small positive scalars. P could be initially 
%       set to a*I where a is the estimated distence between the initial 
%       guess and the optimal valuve. This function can also be used to solve 
%       a set of nonlinear equation, f(x)=0.
%
% This is an example of what a nonlinear Kalman filter can do. It is
% strightforward to replace the unscented Kalman filter with the extended 
% Kalman filter to achieve this same functionality. The advantage of using 
% the unscented Kalman filter is that it is derivative-free. Therefore, it 
% is also suitable for non-analytical functions where no derivatives can 
% be obtained.
%
% Example 1: The Rosenbrock's function is solved within 100 iterations
%{
f=@(x)100*(x(2)-x(1)^2)^2+(1-x(1))^2;
x=ukfopt(f,[2;-1],1e-9,0.45*eye(2))
%}
% Example 2: Solver a set of nonlinear equations represented by MLP NN
%{
rand('state',0);
n=3;
nh=4;
W1=rand(nh,n);
b1=rand(nh,1);
W2=rand(n,nh);
b2=rand(n,1);
x0=zeros(n,1);
f=@(x)W2*tanh(W1*x+b1)+b2;
tol=1e-6;
P=1000*eye(n);
Q=1e-7*eye(n);
R=1e-6*eye(n);
x=ukfopt(f,x0,tol,P,Q,R);
%}
% Example 3: Training a MLP NN. You may have to try several time to get
% results. The best way is to use nnukf.
%{
rand('state',0)
randn('state',0)
N=100;        %training data length
x=randn(1,N); %training data x
y=sin(x);     %training data y=f(x)
nh=4;         %MLP NN hiden nodes
ns=2*nh+nh+1;
f=@(z)y-(z(2*nh+(1:nh))'*tanh(z(1:nh)*x+z(nh+1:2*nh,ones(1,N)))+z(end,ones(1,N)));
theta0=rand(ns,1);
theta=ukfopt(f,theta0,1e-3,0.5*eye(ns),1e-7*eye(ns),1e-6*eye(N));
W1=theta(1:nh);
b1=theta(nh+1:2*nh);
W2=theta(2*nh+(1:nh))';
b2=theta(ns);
M=200;         %Test data length
x1=randn(1,M);
y1=sin(x1);
z1=W2*tanh(W1*x1+b1(:,ones(1,M)))+b2(:,ones(1,M));
plot(x1,y1,'ob',x1,z1,'.r')
legend('Actual','NN model')
%}
%
% By Yi Cao at Cranfield University, 08 January 2008
%

%  Copyright (c) 2009, Yi Cao
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

n=numel(x);     %numer of decision variables
f=@(x)x;        %virtual state equation to update the decision parameter
e=h(x);         %initial residual
m=numel(e);     %number of equations to be solved
if nargin<3,    %default values
    tol=1e-9;
end
if nargin<4
    P=eye(n);
end
if nargin<5
    Q=1e-6*eye(n);
end
if nargin<6
    R=1e-6*eye(m);
end
if nargin<7
    maxit=100;
end
k=1;            %number of iterations
z=zeros(m,1);   %target vector
ne=norm(e);
itc=1;
while ne>tol && itc < maxit
    [x,P]=ukf(f,x,P,h,z,Q,R);               %the unscented Kalman filter
    e=h(x);
    ne=norm(e);                                 %residual
    if 0 && mod(k,100)==1
        fprintf('k=%d e=%g\n',k,ne)    %display iterative information
    end
    k=k+1;                                  %iteration count
end
fprintf('k=%d e=%g\n',k,ne)            %final result

function [x,P]=ukf(fstate,x,P,hmeas,z,Q,R)
% UKF   Unscented Kalman Filter for nonlinear dynamic systems
% [x, P] = ukf(f,x,P,h,z,Q,R) returns state estimate, x and state covariance, P 
% for nonlinear dynamic system (for simplicity, noises are assumed as additive):
%           x_k+1 = f(x_k) + w_k
%           z_k   = h(x_k) + v_k
% where w ~ N(0,Q) meaning w is gaussian noise with covariance Q
%       v ~ N(0,R) meaning v is gaussian noise with covariance R
% Inputs:   f: function handle for f(x)
%           x: "a priori" state estimate
%           P: "a priori" estimated state covariance
%           h: fanction handle for h(x)
%           z: current measurement
%           Q: process noise covariance 
%           R: measurement noise covariance
% Output:   x: "a posteriori" state estimate
%           P: "a posteriori" state covariance
%
% Example:
%{
n=3;      %number of state
q=0.1;    %std of process 
r=0.1;    %std of measurement
Q=q^2*eye(n); % covariance of process
R=r^2;        % covariance of measurement  
f=@(x)[x(2);x(3);0.05*x(1)*(x(2)+x(3))];  % nonlinear state equations
h=@(x)x(1);                               % measurement equation
s=[0;0;1];                                % initial state
x=s+q*randn(3,1); %initial state          % initial state with noise
P = eye(n);                               % initial state covraiance
N=20;                                     % total dynamic steps
xV = zeros(n,N);          %estmate        % allocate memory
sV = zeros(n,N);          %actual
zV = zeros(1,N);
for k=1:N
  z = h(s) + r*randn;                     % measurments
  sV(:,k)= s;                             % save actual state
  zV(k)  = z;                             % save measurment
  [x, P] = ukf(f,x,P,h,z,Q,R);            % ekf 
  xV(:,k) = x;                            % save estimate
  s = f(s) + q*randn(3,1);                % update process 
end
for k=1:3                                 % plot results
  subplot(3,1,k)
  plot(1:N, sV(k,:), '-', 1:N, xV(k,:), '--')
end
%}
%
% By Yi Cao at Cranfield University, 04/01/2008
%
L=numel(x);                                 %numer of states
m=numel(z);                                 %numer of measurements
alpha=1e-3;                                 %default, tunable
ki=0;                                       %default, tunable
beta=2;                                     %default, tunable
lambda=alpha^2*(L+ki)-L;                    %scaling factor
c=L+lambda;                                 %scaling factor
Wm=[lambda/c 0.5/c+zeros(1,2*L)];           %weights for means
Wc=Wm;
Wc(1)=Wc(1)+(1-alpha^2+beta);               %weights for covariance
c=sqrt(c);
X=sigmas(x,P,c);                            %sigma points around x
[x1,X1,P1,X2]=ut(fstate,X,Wm,Wc,L,Q);          %unscented transformation of process
[z1,Z1,P2,Z2]=ut(hmeas,X1,Wm,Wc,m,R);       %unscented transformation of measurments
P12=X2*diag(Wc)*Z2';                        %transformed cross-covariance
R = chol(P2);
K = (P12/R)/R';                             % Filter gain.
% K=P12*inv(P2);
x=x1+K*(z-z1);                              %state update
P=P1-K*P12';                                %covariance update

function [y,Y,P,Y1]=ut(f,X,Wm,Wc,n,R)
%Unscented Transformation
%Input:
%        f: nonlinear map
%        X: sigma points
%       Wm: weights for mean
%       Wc: weights for covraiance
%        n: numer of outputs of f
%        R: additive covariance
%Output:
%        y: transformed mean
%        Y: transformed smapling points
%        P: transformed covariance
%       Y1: transformed deviations

L=size(X,2);
y=zeros(n,1);
Y=zeros(n,L);
for k=1:L                   
    Y(:,k)=f(X(:,k));       
    y=y+Wm(k)*Y(:,k);       
end
Y1=Y-y(:,ones(1,L));
P=Y1*diag(Wc)*Y1'+R;          

function X=sigmas(x,P,c)
%Sigma points around reference point
%Inputs:
%       x: reference point
%       P: covariance
%       c: coefficient
%Output:
%       X: Sigma points

A = c*chol(P)';
Y = x(:,ones(1,numel(x)));
X = [x Y+A Y-A]; 
