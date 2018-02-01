function [V,Vstar,latticestar]=star(lattice)
%===================================================================================
%  function [V,Vst,latticestar]=star(lattice)
%  ResLib v.3.4
%===================================================================================
%
%  Given lattice parametrs, calculate unit cell volume V, reciprocal volume Vstar,
%  and reciprocal lattice parameters.
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================

V=2*lattice.a.*lattice.b.*lattice.c.*sqrt(sin((lattice.alpha+lattice.beta+lattice.gamma)/2).*...
   sin((-lattice.alpha+lattice.beta+lattice.gamma)/2).*...
   sin((lattice.alpha-lattice.beta+lattice.gamma)/2).*...
   sin((lattice.alpha+lattice.beta-lattice.gamma)/2));
Vstar=(2*pi)^3./V;
latticestar.a=2*pi*lattice.b.*lattice.c.*sin(lattice.alpha)./V;
latticestar.b=2*pi*lattice.a.*lattice.c.*sin(lattice.beta)./V;
latticestar.c=2*pi*lattice.b.*lattice.a.*sin(lattice.gamma)./V;
latticestar.alpha=acos( (cos(lattice.beta).*cos(lattice.gamma)-cos(lattice.alpha))./...
   (sin(lattice.beta).*sin(lattice.gamma)) );
latticestar.beta= acos( (cos(lattice.alpha).*cos(lattice.gamma)-cos(lattice.beta))./...
   (sin(lattice.alpha).*sin(lattice.gamma)) );
latticestar.gamma=acos( (cos(lattice.alpha).*cos(lattice.beta)-cos(lattice.gamma))./...
   (sin(lattice.alpha).*sin(lattice.beta)) );
