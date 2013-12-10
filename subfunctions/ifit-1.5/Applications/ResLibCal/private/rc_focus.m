function [rho]=rc_focus(EXP)
%
% MATLAB function to calculate the optimum setting of the
% curvatures for the monochromator and analyser.
%
% input : parameters read from rescal windows
% output: rho returns the matrix of curvatures
%
% ResCal5/DFM 14.5.96
% modified to use EXP structure

% Uses: p(63): EXP.arms(2) L2
%       p(64): EXP.arms(3) L3
%       p(65): EXP.arms(4) L4
%       p(1):  EXP.mono.d
%       p(2):  EXP.ana.d
%       p(9):  EXP.Kfixed
%       p(10): 2*(EXP.infin==-1)+(EXP.infin==1)
%       p(34): EXP.W
if nargin == 0, return; end

f=0.4826;

%----- Spectrometer distances

L1 = EXP.arms(1);
L2 = EXP.arms(2);
L3 = EXP.arms(3);
L4 = EXP.arms(4);

%----- Angles at monochromator and analyser

dm=EXP.mono.d;            % monochromator d-spacing in Angs.
da=EXP.ana.d;             % analyser d-spacing in Angs.
kfix=EXP.Kfixed;          % fixed momentum component in ang-1.
fx=2*(EXP.infin==-1)+(EXP.infin==1);           % fx=1 for fixed incident and 2 for scattered wavevector.
w=EXP.W;                  % energy transfer.
if numel(w) > 1, w = w(ceil(numel(w)/2)); end

ki=sqrt(kfix^2+(fx-1)*f*w);  % kinematical equations.
kf=sqrt(kfix^2-(2-fx)*f*w);

theta_a=asin(pi/(da*kf));      % theta angles for analyser
theta_m=asin(pi/(dm*ki));      % and monochromator.

L= 1/(1/L1+1/L2);
rho.mv=abs(2*L*sin(theta_m));
rho.mh=abs(2*L/sin(theta_m));
L = 1/(1/L3+1/L4);
rho.av=abs(2*L*sin(theta_a));
rho.ah=abs(2*L/sin(theta_a));



