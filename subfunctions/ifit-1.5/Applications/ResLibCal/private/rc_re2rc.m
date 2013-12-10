function [Q2c,Qmag]=rc_re2rc(latt_pars, angles, Qrlu)
%
% RESCAL function to calculate the transformation matrix Q2c
% which allows calculation of coordinates of point in 
% Q space from (h,k,l).
%
% ResCal5/D.F.M.

%----- Real space lattice parameters

a=latt_pars(1);
b=latt_pars(2);
c=latt_pars(3);
alpha=pi*angles(1)/180;
beta =pi*angles(2)/180;
gamma=pi*angles(3)/180;

%----- Real space lattice vectors 

a_vec=a*[1; 0; 0];
b_vec=b*[cos(gamma); sin(gamma); 0];
c1=cos(beta);
c2=(cos(alpha)-cos(gamma)*cos(beta))/sin(gamma);
c3=sqrt(1-c1^2-c2^2);
c_vec=c*[c1; c2; c3;];

%----- Reciprocal space lattice basis vectors

V=dot(a_vec,cross(b_vec,c_vec));

a_star_vec=2*pi*cross(b_vec,c_vec)/V;
b_star_vec=2*pi*cross(c_vec,a_vec)/V;
c_star_vec=2*pi*cross(a_vec,b_vec)/V;

a_star=sqrt(sum(a_star_vec.*a_star_vec));
b_star=sqrt(sum(b_star_vec.*b_star_vec));
c_star=sqrt(sum(c_star_vec.*c_star_vec));

alpha_star=180*acos((cos(beta)*cos(gamma)-cos(alpha))/(sin(beta)*sin(gamma)))/pi;
beta_star=180*acos((cos(gamma)*cos(alpha)-cos(beta))/(sin(gamma)*sin(alpha)))/pi;
gamma_star=180*acos((cos(alpha)*cos(beta)-cos(gamma))/(sin(alpha)*sin(beta)))/pi;


%----- Q vector in cartesian coordinates

H=Qrlu(1); K=Qrlu(2); L=Qrlu(3);
Qcart=H*a_star_vec+K*b_star_vec+L*c_star_vec;
Qmag=sqrt(Qcart(1)^2+Qcart(2)^2+Qcart(3)^2);

%----- Matrix Q2c to transform Q(H,K,L) to cartesian 
%      V=(V1,V2,V3) with V1 || a*, V2 in (a*,b*) plane etc

% Q2c=[a_star b_star*cos(pi*gamma_star/180)    c_star*cos(pi*beta_star/180) ; ...
%     0      b_star*sin(pi*gamma_star/180)   -c_star*sin(pi*beta_star/180)*cos(alpha) ; ...
%     0      0                                2*pi/c];
Q2c=[a_star_vec b_star_vec c_star_vec];
