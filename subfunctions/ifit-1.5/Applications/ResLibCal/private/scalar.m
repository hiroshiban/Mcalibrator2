function s=scalar(x1,y1,z1,x2,y2,z2,lattice)
%===================================================================================
% function s=scalarx1,y1,z1,x2,y2,z2,lattice)
%  ResLib v.3.4
%===================================================================================
%
%  Calculates the scalar product of two vectors, defined by their fractional cell
%  coordinates or Miller indexes.
%
%
% A. Zheludev, 1999-2007
% Oak Ridge National Laboratory
%====================================================================================


s=x1.*x2.*lattice.a.^2+y1.*y2.*lattice.b.^2+z1.*z2.*lattice.c.^2+...
   (x1.*y2+x2.*y1).*lattice.a.*lattice.b.*cos(lattice.gamma)+...
   (x1.*z2+x2.*z1).*lattice.a.*lattice.c.*cos(lattice.beta)+...
   (z1.*y2+z2.*y1).*lattice.c.*lattice.b.*cos(lattice.alpha);
