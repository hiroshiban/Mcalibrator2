function data = read_cif(file)
% mstlread Wrapper to read ascii and binary STL files
  data = [];
  if exist('cif2hkl') == 3 || exist('cif2hkl') == 7 || exist('cif2hkl') == 2
    % use MeX in verbose and no-output-files mode ('-')
    this = cif2hkl(file,[],[],'-',1);
    this = str2struct(this);
    if ~isstruct(this)
      return;
    end
    % search for cell, Atoms and space group
    atoms={'H','He','Li','Be','B','C','N','O','F','Ne','Na','Mg','Al','Si','P','S','Cl','Ar',...
      'K','Ca','Sc','Ti','V','Cr','Mn','Fe','Co','Ni','Cu','Zn','Ga','Ge','As','Se',...
      'Br','Kr','Rb','Sr','Y','Zr','Nb','Mo','Tc','Ru','Rh','Pd','Ag','Cd','In',...
      'Sn','Sb','Te','I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu','Gd',...
      'Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta','W','Re','Os','Ir','Pt','Au',...
      'Hg','Tl','Pb','Bi','Po','At','Rn','Fr','Ra','Ac','Th','Pa','U','Np','Pu',...
      'Am','Cm','Bk','Cf','Es','Fm','Md','No','Lr','Rf','Db','Sg','Bh','Hs','Mt',...
      'Ds','Rg','Cn','Uut','Uuq','Uup','Uuh','Uuo'};
    f = fieldnames(this);
    for j=1:length(f)
      % check if the name of the field is <atom> optionally followed by a number
      [at,nb] = strtok(f{j}, '0123456789'); % supposed to be an atom, and nb is a 'number' or empty
      if any(strcmpi(f{j}, {'Spgr','Spg','Group','SpaceGroup','SubG','SpaceG','SPCGRP','Symb'}))
        if isnumeric(this.(f{j})), this.(f{j}) = num2str(this.(f{j})); end
        data.Spgr = this.(f{j});
      elseif any(strncmpi(f{j}, {'struct','atoms'},5))
        data.structure = this.(f{j});
      elseif any(strcmpi(f{j}, {'cell','lattice'}))
        data.cell = this.(f{j});
      elseif any(strcmp(at, atoms)) && (isempty(nb) || ~isempty(str2num(nb))) && length(this.(f{j})) >= 3 && length(this.(f{j})) <= 7
        % the name of the field is <atom> optionally followed by a number, and value length is 3-7
        data.structure.(f{j}) = this.(f{j});
      end
    end
  else
    disp('cif2hkl is missing: compile it with e.g: ')
    disp('  gfortran -O2 -fPIC -c cif2hkl.f90')
    disp('  mex -O cif2hkl_mex.c cif2hkl.o -o cif2hkl -lgfortran')
    error('Missing cif2hkl MeX')
  end

