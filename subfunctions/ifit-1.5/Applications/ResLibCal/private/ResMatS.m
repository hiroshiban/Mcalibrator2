function [R0,RMS, RM]=ResMatS(H,K,L,W,EXP)
%===================================================================================
%  function [R0,RMS]=ResMatS(H,K,L,W,EXP)
%  ResLib v.3.4
%===================================================================================
%
%  For a scattering vector (H,K,L) and  energy transfers W,
%  given experimental conditions specified in EXP,
%  calculates the Cooper-Nathans resolution matrix RMS and
%  Cooper-Nathans Resolution prefactor R0 in a coordinate system
%  defined by the crystallographic axes of the sample.
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================

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

[R0,RM]= ResMat(Q,W,EXProt);

for i=1:len
   RMS(:,:,i)=(tmat(:,:,i))'*RM(:,:,i)*tmat(:,:,i);
end;

mul=zeros(4,4);
e=eye(4,4);
for i=1:len
    if isfield(EXP(i),'Smooth')
        if ~isempty(EXP(i).Smooth)
            mul(1,1)=1/(EXP(i).Smooth.X^2/8/log(2));
            mul(2,2)=1/(EXP(i).Smooth.Y^2/8/log(2));
            mul(3,3)=1/(EXP(i).Smooth.E^2/8/log(2));
            mul(4,4)=1/(EXP(i).Smooth.Z^2/8/log(2));
            R0(i)=R0(i)/sqrt(det(e/RMS(:,:,i)))*sqrt(det(e/mul+e/RMS(:,:,i)));
            RMS(:,:,i)=e/(e/mul+e/RMS(:,:,i));
        end
    end
end;
