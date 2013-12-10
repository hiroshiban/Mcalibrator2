function RMS=ResLibCal_RM2RMS(H,K,L,W,EXP,RM)
% RMS=ResLibCal_RM2RMS(H,K,L,W,EXP,RM) rotate Resolution matrix in [Q1 Q2] frame

% Calls: CleanArgs, StandardSystem, modvec, scalar

if isempty(RM), RMS=RM; return; end

[len,H,K,L,W,EXP]=CleanArgs(H,K,L,W,EXP);
[x,y,z,sample,rsample]=StandardSystem(EXP);

Q=modvec(H,K,L,rsample);
uq(1,:)=H./Q;  % Unit vector along Q
uq(2,:)=K./Q;
uq(3,:)=L./Q;

xq=scalar(x(1,:),x(2,:),x(3,:),uq(1,:),uq(2,:),uq(3,:),rsample);
yq=scalar(y(1,:),y(2,:),y(3,:),uq(1,:),uq(2,:),uq(3,:),rsample);
zq=0;  %scattering vector assumed to be in (orient1,orient2) plane;

tmat=zeros(4,4,len); %Coordinate transformation matrix
tmat(4,4,:)=1;
tmat(3,3,:)=1;
tmat(1,1,:)=xq;
tmat(1,2,:)=yq;
tmat(2,2,:)=xq;
tmat(2,1,:)=-yq;

RMS=zeros(4,4,len);

for i=1:len
   RMS(:,:,i)=(tmat(:,:,i))'*RM(:,:,i)*tmat(:,:,i);
end;

