function [R0,NP,vi,vf,Error]=rc_cnmat(f,q0,p,mon_flag)
%
% RESCAL  function to calculate the resolution matrix NP in terms of 
% (DQX,DQY,DQZ,DW) defined along the wavevector transfer Q direction 
% in a right hand coordinate system.
%
% The resolution matrix agrees with that calculated using RESCAL from
% the ILL.
%
% Notes: 1. The sign errors in Mitchell's paper have been corrected.
%        2. Error =1 on exit if the scattering triangle does not
%	    close, or imag(NP)~=0.  
%        3. We have followed Dorner and included the kf/ki factor in the
%           normalisation
%        4. The monitor efficiency 1/ki is also included 
%
% Input :       f = Converts from Angs^1 to energy units
%              q0 = Q vector in Angs^-1
%               p = Spectrometer and scan parameters
%         mon_flag= Monitor flag. If mon_flag=1, experiment performed at const. monitor
%                                 If mon_flag=0,    "          "          "     time
%
% Output:       R0= resoltuion volume calculated using Dorner's method.
%               NP= resolution matrix using a matrix method like Mitchell's,
%               vi= incident resolution volume
%               vf= final resolution volume
%            Error= 1, Scattering triangle will not close
%
% ResCal5/AT and DFM, 29.11.95
%

pit=0.0002908882; % This is a conversion from minutes of arc to radians.

%----- INPUT SPECTROMETER PARAMETERS.

dm=p(1);            % monochromator d-spacing in Angs.
da=p(2);            % analyser d-spacing in Angs.
etam=p(3)*pit;      % monochromator mosaic (converted from mins->rads)
etaa=p(4)*pit;      % analyser mosaic.
etas=p(5)*pit;      % sample mosaic.
sm=p(6);            % scattering sense of monochromator (left=+1,right=-1)
ss=p(7);            % scattering sense of sample (left=+1,right=-1)
sa=p(8);            % scattering sense of analyser (left=+1,right=-1)
kfix=p(9);          % fixed momentum component in ang-1.
fx=p(10);           % fx=1 for fixed incident and 2 for scattered wavevector.
alf0=p(11)*pit;     % horizontal pre-monochromator collimation.
alf1=p(12)*pit;     % horizontal pre-sample collimation.
alf2=p(13)*pit;     % horizontal post-sample collimation.
alf3=p(14)*pit;     % horizontal post-analyser collimation.
bet0=p(15)*pit;     % vertical pre-monochromator collimation.
bet1=p(16)*pit;     % vertical pre-sample collimation.
bet2=p(17)*pit;     % vertical post-sample collimation.
bet3=p(18)*pit;     % vertical post-analyser collimation.
w=p(34);            % energy transfer.

% In addition the parameters f, energy pre-multiplier-f*w
% where f=0.48 for meV to ang-2 - and q0 which is the wavevector
% transfer in ang-1, are passed over. 

% Calculate ki and kf, thetam and thetaa

ki=sqrt(kfix^2+(fx-1)*f*w);  % kinematical equations.
kf=sqrt(kfix^2-(2-fx)*f*w);

% Test if scattering triangle is closed

cos_2theta=(ki^2+kf^2-q0^2)/(2*ki*kf);
if cos_2theta <= 1, Error=0; else
  error([ mfilename ': Can not close triangle (kinematical equations).' ]);
end

thetaa=asin(pi/(da*kf));      % theta angles for analyser
thetam=asin(pi/(dm*ki));      % and monochromator.

M=zeros(6,6);
U=M;

% Fill up the horizontal components first.

pm=1/(ki*etam)*[sm*tan(thetam) 1];
palf0=1/(ki*alf0)*[2*sm*tan(thetam) 1];
palf1=1/(ki*alf1)*[0 1];

pa=1/(kf*etaa)*[-sa*tan(thetaa) 1];
palf3=1/(kf*alf3)*[-2*sa*tan(thetaa) 1];
palf2=1/(kf*alf2)*[0 1];


M(1:2,1:2)=pm'*pm+palf0'*palf0+palf1'*palf1;
M(4:5,4:5)=pa'*pa+palf3'*palf3+palf2'*palf2;

% Now fill up the vertical components.

b1=1/(bet1^2)+1/((2*sin(thetam)*etam)^2+bet0^2);  % these are Dorner's 
b2=1/(bet2^2)+1/((2*sin(thetaa)*etaa)^2+bet3^2);  % corrected formulae.

M(3,3)=1/(ki^2)*b1;
M(6,6)=1/(kf^2)*b2;

% The resolution matrix in terms of the incident and scattered
% momentum 3-vectors has been constructed.

% Now calculate the transformation matrix.
%

ang1=acos(-(kf^2-q0^2-ki^2)/(2*q0*ki));    % angle between ki and q0
ang2=pi-acos(-(ki*ki-q0*q0-kf*kf)/(2*q0*kf)); % angle between kf and q0

TI=[ cos(ang1) -ss*sin(ang1) ; ss*sin(ang1) cos(ang1) ]; % transform kix,kiy
                                                         % to DQX and DQY.
TF=[ cos(ang2) -ss*sin(ang2) ; ss*sin(ang2) cos(ang2) ]; % transform Kfx,kfy
                                                         % to DQX and DQY.

U(1:2,1:2)=TI;
U(1:2,4:5)=-TF;
U(3,3)=1;
U(3,6)=-1;
U(4,1)=2*ki/f;
U(4,4)=-2*kf/f;
U(5,1)=1;
U(6,3)=1;
V=inv(U);

N=V'*M*V;                           % put into coordinates DQ(3),DW,kix,kiz
dummy=1;

[dummy,N]=rc_int(6,dummy,N);        % integrate over kiz giving a 5x5 matrix
[dummy,N]=rc_int(5,dummy,N);        % integrate over kix giving a 4x4 matrix
NP=N-N(1:4,2)*N(1:4,2)'/(1/((etas*q0)^2)+N(2,2));
NP(3,3)=N(3,3);
NP=5.545*NP;                        % Correction factor 8*log(2) as input parameters
                                    % are expressed as FWHM.

%----- Normalisation factor

mon=1;          % monochromator reflectivity
ana=1;          % detector and analyser crystal efficiency function. (const.)

if mon_flag==1 
   vi=1;     
else
   vi=mon*ki^3*cot(thetam)*15.75*bet0*bet1*etam*alf0*alf1;
   vi=vi/sqrt((2*sin(thetam)*etam)^2+bet0^2+bet1^2);
   vi=vi/sqrt(alf0^2+alf1^2+4*etam^2);             
end

vf=ana*kf^3*cot(thetaa)*15.75*bet2*bet3*etaa*alf2*alf3;
vf=vf/sqrt((2*sin(thetaa)*etaa)^2+bet2^2+bet3^2);
vf=vf/sqrt(alf2^2+alf3^2+4*etaa^2);
                            
R0=vi*vf*sqrt(det(NP))/(2*pi)^2;          % Dorner form of resolution normalisation
                                          % see Mitchell, Cowley and Higgins. 
R0=R0/(etas*sqrt(1/etas^2+q0^2*N(2,2)));  % Werner and Pynn correction
                                          % for mosaic spread of crystal.

%----- Final error check

if imag(NP) == 0; Error=0; else; Error=1; end

return
