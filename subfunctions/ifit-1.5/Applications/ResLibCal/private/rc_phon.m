function [rp,fwhm]=rc_phon(r0,M,C)

%
% MATLAB  routine to calculate the phonon width of a scan along a 
% vector s, and a plane defined by C.X=w. r0 is the resolution constant and
% M is the resolution matrix.
%
% A.T.

T=diag(ones(4,1),0);
T(4,1:4)=C;
S=inv(T);
MP=S'*M*S;
[rp,MP]=rc_int(1,r0,MP);
[rp,MP]=rc_int(1,rp,MP);
[rp,MP]=rc_int(1,rp,MP);
fwhm=2.35482/sqrt(MP(1,1));

