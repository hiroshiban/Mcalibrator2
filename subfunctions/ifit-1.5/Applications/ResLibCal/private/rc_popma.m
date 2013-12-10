function [R0,M,vi,vf,Error]=rc_popma(f,q0,p,mon_flag)
% New version which includes spatial effects.
% Based on the paper M. Popovici, Acta Cryst. (1975) A31, 507.
% MATLAB  function to calculate the resolution matrix NP in terms of 
% (DQX,DQY,DQZ,DW) defined along the wavevector transfer Q direction 
% in a right hand coordinate system.
%
% The resolution matrix agrees with that calculated using RESCAL from
% the ILL.
%
% Notes: 1. The sign errors in Mitchell's paper have been corrected.
%        2. Error =1 on exit if the scattering triangle does not
%	    close, or imag(M)~=0.  
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
%               M = resolution matrix using a matrix method like Mitchell's,
%               vi= incident resolution volume
%               vf= final resolution volume
%            Error= 1, Scattering triangle will not close
%
% ResCal5/AT and DFM, 29.11.95
%		run time = 0.03 seconds (approx.).
% Debug status:	The resolution matrix has been checked against
%		restrax and agreement is found when the poisson
%		ratio is set to zero and the sample mosaic (neither
%		are inclucde as yet in this program) is also set
%		to zero.

pit=2*pi/(360*60); % convert arcmin -> radians=2*pi/(360*60)

%----- INPUT SPECTROMETER PARAMETERS.

dm=p(1);            % monochromator d-spacing in Angs.
da=p(2);            % analyser d-spacing in Angs.
etam=p(3)*pit;      % monochromator mosaic (converted from mins->rads)
etamp=etam;         % vertical mosaic of the monochromator.
etaa=p(4)*pit;      % analyser mosaic.
etaap=etaa;         % vertical mosaic spread of the analyser.
etas=p(5)*pit;      % sample mosaic.
etasp=etas;	    % vertical mosaic spread of the sample.
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

% _____________________Extra Parameters________________________________________
offset=42;

nsou=p(1+offset);                % =0 for circular source, =1 for rectangular source.
ysrc=p(2+offset);                % width/diameter of the source (cm).
zsrc=p(3+offset);                % height/diameter of the source (cm).

flag_guide=p(4+offset);          % =0 for no guide, =1 for guide.
guide_h=p(5+offset);             % horizontal guide divergence (mins/Angs)
guide_v=p(6+offset);             % vertical guide divergence (mins/Angs)

nsam=p(7+offset);                % =0 for cylindrical sample, =1 for cuboid sample.
xsam=p(8+offset);                % sample depth/diameter perp. to Q (cm).
ysam=p(9+offset);                % sample width/diameter along Q (cm). 
zsam=p(10+offset);               % sample height (cm).

ndet=p(11+offset);               % =0 for circular detector, =1 for rectangular detector.
ydet=p(12+offset);               % width/diameter of the detector (cm).
zdet=p(13+offset);               % height/diameter of the detector (cm).

xmon=p(14+offset);               % thickness of monochromator (cm).
ymon=p(15+offset);               % width of monochromator (cm).
zmon=p(16+offset);               % height of monochromator (cm).

xana=p(17+offset);               % thickness of analyser (cm).
yana=p(18+offset);               % width of analyser (cm).
zana=p(19+offset);               % height of analyser (cm).

L0=p(20+offset);                 % distance between source and monochromator (cm).
L1=p(21+offset);                 % distance between monochromator and sample (cm).
L2=p(22+offset);                 % distance between sample and analyser (cm).
L3=p(23+offset);                 % distance between analyser and detector (cm).

% TODO: FIX removed /100 so that all distances are in [cm]. 
%       Was converted to [m-1] whereas all other distances are in [cm-1] !!
romh=sm*abs(p(24+offset)); % horizontal curvature of monochromator 1/radius (cm-1).
romv=sm*abs(p(25+offset));    % vertical curvature of monochromator (cm-1).
roah=sa*abs(p(26+offset)); % horizontal curvature of analyser (cm-1).
roav=sa*abs(p(27+offset));    % vertical curvature of analyser (cm-1).

f16=1/16.;
f12=1/12.;
% _____________________________________________________________________________

% In addition the parameters f, energy pre-multiplier-f*w
% where f=0.48 for meV to ang-2 - and q0 which is the wavevector
% transfer in ang-1, are passed over. 

% Calculate ki and kf, thetam and thetaa

ki=sqrt(kfix^2+(fx-1)*f*w);  % kinematical equations.
kf=sqrt(kfix^2-(2-fx)*f*w);

% Test if scattering triangle is closed

cos_2theta=(ki^2+kf^2-q0^2)/(2*ki*kf);
if cos_2theta <= 1, Error=0; else, Error=1; end

thetaa=sa*asin(pi/(da*kf));      % theta angles for analyser
thetam=sm*asin(pi/(dm*ki));      % and monochromator.
thetas=ss*0.5*acos((ki^2+kf^2-q0^2)/(2*ki*kf)); % scattering angle from sample.
phi=atan2(-kf*sin(2*thetas),ki-kf*cos(2*thetas));

% Make up the matrices in appendix 1 of M.Popovici (1975).

% First check for incident guide

if flag_guide == 1, alf0=pit*2*pi*guide_h/ki; bet0=pit*2*pi*guide_v/ki; end 

G=zeros(8,8);
G(1,1)=1/alf0^2;	% horizontal and vertical collimation matrix.
G(2,2)=1/alf1^2;
G(3,3)=1/bet0^2;
G(4,4)=1/bet1^2;
G(5,5)=1/alf2^2;
G(6,6)=1/alf3^2;
G(7,7)=1/bet2^2;
G(8,8)=1/bet3^2;

F=zeros(4,4);
F(1,1)=1/etam^2;	% monochromator and analyser mosaic matrix. 
F(2,2)=1/etamp^2;
F(3,3)=1/etaa^2;
F(4,4)=1/etaap^2;

C=zeros(4,8);
C(1,1)=1/2;
C(1,2)=C(1,1);
C(3,5)=C(1,1);
C(3,6)=C(1,1);
C(2,3)=1/(2*sin(thetam));
C(2,4)=-C(2,3);
C(4,7)=1/(2*sin(thetaa));
C(4,8)=-C(4,7);

A=zeros(6,8);
A(1,1)=ki*cot(thetam)/2;
A(1,2)=-A(1,1);
A(2,2)=ki;
A(3,4)=A(2,2);
A(4,5)=kf*cot(thetaa)/2;
A(4,6)=-A(4,5);
A(5,5)=kf;
A(6,7)=A(5,5);

B=zeros(4,6);
B(1,1)=cos(phi);
B(1,2)=sin(phi);
B(1,4)=-cos(phi-2*thetas);
B(1,5)=-sin(phi-2*thetas);
B(2,1)=-B(1,2);
B(2,2)=B(1,1);
B(2,4)=-B(1,5);
B(2,5)=B(1,4);
B(3,3)=1;
B(3,6)=-1;
B(4,1)=2*ki/f;
B(4,4)=-2*kf/f;

% Now include the spatial effects.

S1I=zeros(3,3);
% --- monitor spatial covariances ----------
factor=f12;
S1I(1,1)=factor*xmon^2;
S1I(2,2)=factor*ymon^2;
S1I(3,3)=factor*zmon^2;
S2I=zeros(3,3);
% --- sample spatial covariances -----------
if nsam==0, factor=f16; else, factor=f12; end
S2I(1,1)=factor*xsam^2;
S2I(2,2)=factor*ysam^2;
S2I(3,3)=f12*zsam^2;
% --- analyser spatial covariances ---------
factor=f12;
S3I=zeros(3,3);
S3I(1,1)=factor*xana^2;
S3I(2,2)=factor*yana^2;
S3I(3,3)=factor*zana^2;
% --- construct the full spatial covariance matrix
SI=zeros(13,13);
% --- source covariance --------------------
if nsou==0
factor=f16;               % factor for converting diameter^2 to variance^2
else
factor=f12;               % factor for converting width^2 to variance^2.
end
SI(1,1)=factor*ysrc^2;
SI(2,2)=factor*zsrc^2; 
% --- add in the mono. sample & analyser ---
SI(3:5,3:5)=S1I;
SI(6:8,6:8)=S2I;
SI(9:11,9:11)=S3I;
% --- detector covariance ------------------
if ndet==0, factor=f16; else, factor=f12; end 
SI(12,12)=factor*ydet^2;
SI(13,13)=factor*zdet^2;
SI;
S=inv(SI); % was 5.545*SI

T=zeros(4,13);
T(1,1)=-1/(2*L0);
T(1,3)=cos(thetam)*(1/L1-1/L0)/2;
T(1,4)=sin(thetam)*(1/L0+1/L1-2*romh/(sin(thetam)))/2;
T(1,6)=sin(thetas)/(2*L1);
T(1,7)=cos(thetas)/(2*L1);
T(2,2)=-1/(2*L0*sin(thetam));
T(2,5)=(1/L0+1/L1-2*sin(thetam)*romv)/(2*sin(thetam));
T(2,8)=-1/(2*L1*sin(thetam));
T(3,6)=sin(thetas)/(2*L2);
T(3,7)=-cos(thetas)/(2*L2);
T(3,9)=cos(thetaa)*(1/L3-1/L2)/2;
T(3,10)=sin(thetaa)*(1/L2+1/L3-2*roah/(sin(thetaa)))/2;
T(3,12)=1/(2*L3);
T(4,8)=-1/(2*L2*sin(thetaa));
T(4,11)=(1/L2+1/L3-2*sin(thetaa)*roav)/(2*sin(thetaa));
T(4,13)=-1/(2*L3*sin(thetaa));

D=zeros(8,13);
D(1,1)=-1/L0;
D(1,3)=-cos(thetam)/L0;
D(1,4)=sin(thetam)/L0;
D(3,2)=D(1,1);
D(3,5)=-D(1,1);
D(2,3)=cos(thetam)/L1;
D(2,4)=sin(thetam)/L1;
D(2,6)=sin(thetas)/L1;
D(2,7)=cos(thetas)/L1;
D(4,5)=-1/L1;
D(4,8)=-D(4,5);
D(5,6)=sin(thetas)/L2;
D(5,7)=-cos(thetas)/L2;
D(5,9)=-cos(thetaa)/L2;
D(5,10)=sin(thetaa)/L2;
D(7,8)=-1/L2;
D(7,11)=-D(7,8);
D(6,9)=cos(thetaa)/L3;
D(6,10)=sin(thetaa)/L3;
D(6,12)=1/L3;
D(8,11)=-D(6,12);
D(8,13)=D(6,12);

% Construction of the resolution matrix

% Popovici inverse matrix
MI=B*A*(inv(inv(D*(inv(S+T'*F*T))*D')+G))*A'*B'; % including spatial effects.

% Cooper and Nathans inverse matrix
%MI=B*A*(inv(G+C'*F*C))*A'*B'

% take mosaic into account 
MI(2,2)=MI(2,2)+q0^2*etas^2;
MI(3,3)=MI(3,3)+q0^2*etasp^2;
M=5.545*inv(MI);  % Correction factor 8*log(2) as input parameters
                  % are expressed as FWHM. 

%----- Normalisation factor

mon=1;          % monochromator reflectivity
ana=1;          % detector and analyser crystal efficiency function. (const.)

if mon_flag==1 
   vi=1;     
else
   vi=mon*ki^3*cot(thetam)*15.75*bet0*bet1*etam*alf0*alf1;
   vi=vi/sqrt((2*sin(thetam)*etam)^2+bet0^2+bet1^2);
   vi=abs(vi/sqrt(alf0^2+alf1^2+4*etam^2));             
end

vf=ana*kf^3*cot(thetaa)*15.75*bet2*bet3*etaa*alf2*alf3;
vf=vf/sqrt((2*sin(thetaa)*etaa)^2+bet2^2+bet3^2);
vf=abs(vf/sqrt(alf2^2+alf3^2+4*etaa^2));
                            
R0=vi*vf*sqrt(det(M))/(2*pi)^2;  % Dorner form of resolution normalisation
                                  % see Mitchell, Cowley and Higgins. 
% TODO: FIX added *M(3,3) to 1/etas^2 term
R0=abs(R0/(etas*sqrt(1/etas^2+q0^2*M(2,2))));  % Werner and Pynn correction
                                          % for mosaic spread of crystal.

%----- Final error check

if imag(M) == 0; Error=0; else; Error=1; end

return

