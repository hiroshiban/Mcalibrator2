function [lattice,rlattice]=GetLattice(EXP)
%===================================================================================
%  function [lattice,rlattice]=GetLattice(EXP)
%  Extracts lattice parameters from EXP and returns the direct and reciprocal lattice
%  parameters in the form used by scalar.m, star.m,etc.
%  This function is part of ResLib v.3.4
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================
s=[EXP(:).sample];
lattice.a=[s(:).a];
lattice.b=[s(:).b];
lattice.c=[s(:).c];
lattice.alpha=[s(:).alpha]*pi/180;
lattice.beta=[s(:).beta]*pi/180;
lattice.gamma=[s(:).gamma]*pi/180;
[V,Vstar,rlattice]=star(lattice);
