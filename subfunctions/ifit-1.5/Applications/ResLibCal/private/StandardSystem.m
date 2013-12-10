function [x,y,z,lattice,rlattice]=StandardSystem(EXP)
%===================================================================================
%  function [x,y,z,lattice,rlattice]=StandardSystem(EXP)
%  This function is part of ResLib v.3.4
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================

[lattice,rlattice]=GetLattice(EXP);
len=length(EXP);


orient1=zeros(3,len);
orient1(:)=[EXP(:).orient1];
orient2=zeros(3,len);
orient2(:)=[EXP(:).orient2];

modx=modvec(orient1(1,:),orient1(2,:),orient1(3,:),rlattice);

x=orient1;
x(1,:)=x(1,:)./modx; % First unit basis vector
x(2,:)=x(2,:)./modx;
x(3,:)=x(3,:)./modx;


proj=scalar(orient2(1,:),orient2(2,:),orient2(3,:),x(1,:),x(2,:),x(3,:),rlattice);

y=orient2;

y(1,:)=y(1,:)-x(1,:).*proj; 
y(2,:)=y(2,:)-x(2,:).*proj;
y(3,:)=y(3,:)-x(3,:).*proj;

mody=modvec(y(1,:),y(2,:),y(3,:),rlattice);

if ~isempty(find(mody<=0))
   error('??? Fatal error: Orienting vectors are colinear!');
end;


y(1,:)=y(1,:)./mody; % Second unit basis vector
y(2,:)=y(2,:)./mody;
y(3,:)=y(3,:)./mody;

z=y;

z(1,:)=x(2,:).*y(3,:)-y(2,:).*x(3,:);
z(2,:)=x(3,:).*y(1,:)-y(3,:).*x(1,:);
z(3,:)=-x(2,:).*y(1,:)+y(2,:).*x(1,:);

proj=scalar(z(1,:),z(2,:),z(3,:),x(1,:),x(2,:),x(3,:),rlattice);

z(1,:)=z(1,:)-x(1,:).*proj; 
z(2,:)=z(2,:)-x(2,:).*proj;
z(3,:)=z(3,:)-x(3,:).*proj;

proj=scalar(z(1,:),z(2,:),z(3,:),y(1,:),y(2,:),y(3,:),rlattice);

z(1,:)=z(1,:)-y(1,:).*proj; 
z(2,:)=z(2,:)-y(2,:).*proj;
z(3,:)=z(3,:)-y(3,:).*proj;

modz=modvec(z(1,:),z(2,:),z(3,:),rlattice);

z(1,:)=z(1,:)./modz; % Third unit basis vector
z(2,:)=z(2,:)./modz;
z(3,:)=z(3,:)./modz;
