function m=modvec(x,y,z,lattice)
%===================================================================================
% function m=modvec(x,y,z,lattice)
%  ResLib v.3.4
%===================================================================================
%
%  Calculates the modulus of a vector, defined by its fractional cell coordinates or
%  Miller indexes.
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================

m=sqrt( scalar(x,y,z,x,y,z,lattice) );
