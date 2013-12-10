function b=load_stl(a)
% function a=load_stl(a)
%
% Returns an iData style dataset from a STL file (ascii or binary)
% or an OFF, PLY, CFL, EZD file

vertices = []; faces = [];
if isfield(a.Data.MetaData, 'OFF')
  % this is an OFF format file read by looktxt
  nvf=a.Data.MetaData.OFF;      % 'NVertices  NFaces  NEdges'
  nv=nvf(1,1); nf=nvf(1,2);     % indices start at 0 in OFF
  % get the vertices: the vertices are in an 'OFF' block
  % should all have same columns >= 3
  % and 1st column is not integer
  [match,type,n] = findfield(a, 'OFF');
  nvf = [];
  for index=1:length(n)
    if strcmp(type{index}, 'char'), continue; end
    f=get(a,match{index});
    if ~isnumeric(f) || isempty(f) || isvector(f), continue; end
    isvertex = find(f(:,1) ~= size(f,2)-1 & f(:,1) ~= floor(f(:,1))); % 1st column not a number of vertices
    if size(f, 2) >= 3 && length(isvertex) >= 3 % at least 3 point to define a face
      if     isempty(nvf), nvf = f(isvertex,:);
      elseif size(nvf,2) == size(f,2)
        nvf = [ nvf ; f(isvertex,:) ];
      end
      f(isvertex,:) = [];    % remove the vertex lines we got
      a.(match{index}) = f;
    end
  end
  nv       = size(nvf,1);
  vertices = nvf;
  a.Data.MetaData.OFF = [ nv nf ];
elseif strncmpi(a.Format, 'ply',3)
  nf = a.Data.face;
  nv = a.Data.vertex;
  % the data block is Data.end_header in all cases
  nvf= a.Data.end_header;
  a.Data.end_header = [];
elseif strncmpi(a.Format, 'CFL',3)
  % get Atom Section and build a vertex list from all entries matching atoms
  if isfield(a.Data,'Atom')
    Atom = a.Data.Atom;
  elseif isfield(a.Data,'structure')
    Atom = a.Data.structure;
  else
    Atom = a.Data;
  end
  f = fieldnames(Atom);
  vertices = [];
  atoms={'H','He','Li','Be','B','C','N','O','F','Ne','Na','Mg','Al','Si','P','S','Cl','Ar',...
      'K','Ca','Sc','Ti','V','Cr','Mn','Fe','Co','Ni','Cu','Zn','Ga','Ge','As','Se',...
      'Br','Kr','Rb','Sr','Y','Zr','Nb','Mo','Tc','Ru','Rh','Pd','Ag','Cd','In',...
      'Sn','Sb','Te','I','Xe','Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu','Gd',...
      'Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta','W','Re','Os','Ir','Pt','Au',...
      'Hg','Tl','Pb','Bi','Po','At','Rn','Fr','Ra','Ac','Th','Pa','U','Np','Pu',...
      'Am','Cm','Bk','Cf','Es','Fm','Md','No','Lr','Rf','Db','Sg','Bh','Hs','Mt',...
      'Ds','Rg','Cn','Uut','Uuq','Uup','Uuh','Uuo'};
  for index=1:length(f)
    [at,nb] = strtok(f{index}, '0123456789'); % supposed to be an atom, and nb is a 'number' or empty
    if isnumeric(Atom.(f{index})) && ~isempty(Atom.(f{index})) && sum(strcmpi(at, atoms)) == 1
      l = Atom.(f{index}); %l=l(:)';
      vertices = [ vertices ; l ];
    end
  end
  nv = size(vertices, 1); nf = 0;
end

if isfield(a.Data.MetaData, 'OFF') || strncmpi(a.Format, 'ply',3)
  if size(nvf,1) <= nv+nf  % only contains vertices: an other block gives the faces...
    vertices=nvf(1:nv,:);
    nvf = [];
    [match,type,n] = findfield(a);
    % sort fields by size
    [n,sorti]=sort(n,'descend');
    for index=1:length(n)
      if strcmp(type{sorti(index)}, 'char'), continue; end
      f=get(a,match{sorti(index)});
      if ~isnumeric(f) || isempty(f) || isvector(f), continue; end       % only get block with numeric data
      isface = find(f(:,1) == size(f,2)-1 & f(:,1) >= 3); % 1st column is a number of vertices in face
      if size(f, 2) >= 4 && length(isface) >= 1
        if     isempty(nvf), nvf = f(isface,2:end)+1;
        elseif size(nvf,2) == size(f,2)
          nvf = [ nvf ; f(isface,2:end)+1 ];
        end
        f(isface,:) = [];    % remove the vertex lines we got
        a.(match{sorti(index)}) = f;
      end
    end
    nf    = size(nvf,1);
    faces = nvf;
  else
    vertices=nvf(1:nv,:);
    faces   =nvf(nv:end,2:end)+1;
  end
end  

% store the vertices and faces
if isempty(vertices)
  warning([ mfilename ': The loaded data set ' a.Tag ' from ' a.Source ' is not a STL/SLP/OFF/PLY/CFL/EZD data format.' ]); 
  b = a;
  return
end

a.Data.vertices = vertices;
a.Data.vertex   = size(a.Data.vertices,1);
if nf
  a.Data.faces    = faces;
  a.Data.face     = size(a.Data.faces,1);
else
  a.Data.faces    = [];
  a.Data.face     = 0;
end
if isfield(a.Data,'MetaData')
  a.Data.MetaData.OFF = [ size(a.Data.vertices,1) size(a.Data.faces,1) ];
end


a.Data.Signal=ones(size(a.Data.vertices, 1),1);
setalias(a, 'Signal', 'Data.Signal');
setalias(a, 'X', 'Data.vertices(:,1)');
setalias(a, 'Y', 'Data.vertices(:,2)');
setalias(a, 'Z', 'Data.vertices(:,3)');

setaxis(a, 1, 'X'); setaxis(a, 2, 'Y'); setaxis(a, 3, 'Z');

b=a;
