function EXP=ResLibCal_SampleRotateS(H,K,L,EXP)
% EXP=ResLibCal_SampleRotateS(H,K,L,EXP): rotate the sample.shape in Q1 Q2 frame
%

% Calls: CleanArgs, StandardSystem, scalar

[len,H,K,L,W,EXP]=CleanArgs(H,K,L,0,EXP);
[x,y,z,sample,rsample]=StandardSystem(EXP);

Q=modvec(H,K,L,rsample);
EXP.QM = Q;
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
rot=zeros(3,3);
EXProt=EXP;

%Sample shape matrix in coordinate system defined by scattering vector
for i=1:len
    sample=EXP(i).sample;
    if isfield(sample,'shape')
        rot(1,1)=tmat(1,1,i);
        rot(2,1)=tmat(2,1,i);
        rot(1,2)=tmat(1,2,i);
        rot(2,2)=tmat(2,2,i);
        rot(3,3)=tmat(3,3,i);
        EXProt(i).sample.shape=rot*sample.shape*rot';
    end;
end
EXProt.sample.depth = 12*EXProt.sample.shape(1,1)^2;
EXProt.sample.width = 12*EXProt.sample.shape(2,2)^2;
EXP = EXProt;

