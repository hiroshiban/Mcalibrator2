function [R0,RM]=ResMat(Q,W,EXP)
%===================================================================================
%  function [R0,RM]=ResMat(Q,W,EXP)
%  ResLib v.3.4
%===================================================================================
%
%  For a momentum transfer Q and energy transfers W,
%  given experimental conditions specified in EXP,
%  calculates the Cooper-Nathans resolution matrix RM and
%  Cooper-Nathans Resolution prefactor R0.
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================

% 0.424660900144 = FWHM2RMS
% CONVERT1=0.4246609*pi/60/180;
CONVERT1=pi/60/180; % TODO: FIX constant from from CN. 0.4246
CONVERT2=2.072;

[len,Q,W,EXP]=CleanArgs(Q,W,EXP);

RM=zeros(4,4,len);
R0=zeros(1,len);
RM_=zeros(4,4);
D=zeros(8,13);
d=zeros(4,7);
T=zeros(4,13);
t=zeros(2,7);
A=zeros(6,8);
C=zeros(4,8);
B=zeros(4,6);
for ind=1:len
    %---------------------------------------------------------------------------------------------
    %Assign default values and decode parameters
    moncor=1;
    if isfield(EXP(ind),'moncor')
        moncor = EXP(ind).moncor;
    end;
    alpha = EXP(ind).hcol*CONVERT1;
    beta =  EXP(ind).vcol*CONVERT1;
    mono=EXP(ind).mono;
    etam = mono.mosaic*CONVERT1;
    etamv=etam;
    if isfield(mono,'vmosaic')
        etamv = mono.vmosaic*CONVERT1;
    end;
    ana=EXP(ind).ana;
    etaa = ana.mosaic*CONVERT1;
    etaav=etaa;
    if isfield(ana,'vmosaic')
        etaav = ana.vmosaic*CONVERT1;
    end;
    sample=EXP(ind).sample;
    infin=-1;
    if isfield(EXP(ind),'infin')
        infin = EXP(ind).infin;
    end;
    efixed=EXP(ind).efixed;
    epm=1;
    if isfield(EXP(ind),'dir1')
        epm= EXP(ind).dir1;
    end;
    ep=1;
    if isfield(EXP(ind),'dir2')
        ep= EXP(ind).dir2;
    end;
    monitorw=1;
    monitorh=1;
    beamw=1;
    beamh=1;
    monow=1;
    monoh=1;
    monod=1;
    anaw=1;
    anah=1;
    anad=1;
    detectorw=1;
    detectorh=1;
    sshape=eye(3);
    L0=1;
    L1=1;
    L1mon=1;
    L2=1;
    L3=1;        
    monorv=1e6;
    monorh=1e6;
    anarv=1e6;
    anarh=1e6;
    if isfield(EXP(ind),'beam')
        beam=EXP(ind).beam;
        if isfield(beam,'width')
            beamw=beam.width^2/12;
        end;
        if isfield(beam,'height')
            beamh=beam.height^2/12;
        end;
    end;
    bshape=diag([beamw,beamh]);
    if isfield(EXP(ind),'monitor')
        monitor=EXP(ind).monitor;
        if isfield(monitor,'width')
            monitorw=monitor.width^2/12;
        end;
        monitorh=monitorw;
        if isfield(monitor,'height')
            monitorh=monitor.height^2/12;
        end;
    end;
    monitorshape=diag([monitorw,monitorh]);
    if isfield(EXP(ind),'detector')
        detector=EXP(ind).detector;
        if isfield(detector,'width')
            detectorw=detector.width^2/12;
        end;
        if isfield(detector,'height')
            detectorh=detector.height^2/12;
        end;
    end;
    dshape=diag([detectorw,detectorh]);
    if isfield(mono,'width')
        monow=mono.width^2/12;
    end;
    if isfield(mono,'height')
        monoh=mono.height^2/12;
    end;
    if isfield(mono,'depth')
        monod=mono.depth^2/12;
    end;
    mshape=diag([monod,monow,monoh]);
    if isfield(ana,'width')
        anaw=ana.width^2/12;
    end;
    if isfield(ana,'height')
        anah=ana.height^2/12;
    end;
    if isfield(ana,'depth')
        anad=ana.depth^2/12;
    end;
    ashape=diag([anad,anaw,anah]);
    if isfield(sample,'width') && isfield(sample,'depth') && isfield(sample, 'height')
        sshape=diag([ sample.depth sample.width sample.height ].^2/12);
    elseif isfield(sample,'shape')
        sshape=sample.shape/12;
    end;
    if isfield(EXP(ind),'arms')
        arms=EXP(ind).arms;
        L0=arms(1);
        L1=arms(2);
        L2=arms(3);
        L3=arms(4);
        L1mon=L1;
        if length(arms)>4
            L1mon=arms(5);
        end
    end;
    if isfield(mono,'rv')
        monorv=mono.rv;
    end;
    if isfield(mono,'rh')
        monorh=mono.rh;
    end;
    if isfield(ana,'rv')
        anarv=ana.rv;
    end;
    if isfield(ana,'rh')
        anarh=ana.rh;
    end;
    method=0;
    if isfield(EXP(ind),'method')
        method=EXP(ind).method;
    end;
    
    taum=GetTau(mono.tau);
    taua=GetTau(ana.tau);

    horifoc=-1;
    if isfield(EXP(ind),'horifoc')
        horifoc=EXP(ind).horifoc;
    end;
    % TODO: FIX removed as CN has no focusing, and it scrambles M
    if horifoc==1 && 0
        alpha(3)=alpha(3)*sqrt(8*log(2)/12); 
    end;
    
    em=1;
        if isfield(EXP(ind),'mondir')

        em= EXP(ind).mondir;
    end;
    sm =EXP.mono.dir;
    ss =EXP.sample.dir;
    sa =EXP.ana.dir;
    % TODO: FIX: direction of curvature was missing
    monorh = sm*abs(monorh);
    monorv = sm*abs(monorv);
    anarh  = sa*abs(anarh);
    anarv  = sa*abs(anarv);

    %---------------------------------------------------------------------------------------------
    %Calculate angles and energies
    w=W(ind);
    q=Q(ind);
    ei=efixed;
    ef=efixed;
    if infin>0 ef=efixed-w; else ei=efixed+w; end;
    ki = sqrt(ei/CONVERT2);
    kf = sqrt(ef/CONVERT2);
    
    thetam=asin(taum/(2*ki))*sm; % added sign(em) K.P.
    thetaa=asin(taua/(2*kf))*sa; 
    s2theta=acos( (ki^2+kf^2-q^2)/(2*ki*kf))*ss; %2theta sample


    thetas=s2theta/2;
%   phi=atan2(-kf*sin(s2theta), ki-kf*cos(s2theta)); %Angle from ki to Q
%   The following correction was suggested by Sibel Bayracki
    phi=atan2((-kf*sin(s2theta)), (ki-kf*cos(s2theta)));
    %---------------------------------------------------------------------------------------------
    %Calculate beam divergences defined by neutron guides
    % TODO: FIX ? 0.427/sqrt(3) is a strange factor ? why ?
    
    if alpha(1)<0  alpha(1)=-alpha(1)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    if alpha(2)<0  alpha(2)=-alpha(2)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    if alpha(3)<0  alpha(3)=-alpha(3)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    if alpha(4)<0  alpha(4)=-alpha(4)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    
    if beta(1)<0  beta(1)=-beta(1)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    if beta(2)<0  beta(2)=-beta(2)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    if beta(3)<0  beta(3)=-beta(3)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
    if beta(4)<0  beta(4)=-beta(4)*0.1*60*(2*pi/ki)/0.427/sqrt(3); end
     %---------------------------------------------------------------------------------------------
    %Redefine sample geometry
    psi=thetas-phi; %Angle from sample geometry X axis to Q
    rot=zeros(3,3);
    rot(1,1)=cos(psi);
    rot(2,2)=cos(psi);
    rot(1,2)=sin(psi);
    rot(2,1)=-sin(psi);
    rot(3,3)=1;
%    sshape=rot'*sshape*rot;
    sshape=rot*sshape*rot';
    %---------------------------------------------------------------------------------------------
    %Definition of matrix G    
    G=1./([alpha(1),alpha(2),beta(1),beta(2),alpha(3),alpha(4),beta(3),beta(4)]).^2;
    G=diag(G);
    %---------------------------------------------------------------------------------------------
    %Definition of matrix F    
    F=1./([etam,etamv,etaa,etaav]).^2;
    F=diag(F);
    %---------------------------------------------------------------------------------------------
    %Definition of matrix A
    A(1,1)=ki/2/tan(thetam);
    A(1,2)=-A(1,1);
    A(4,5)=kf/2/tan(thetaa);
    A(4,6)=-A(4,5);
    A(2,2)=ki;
    A(3,4)=ki;
    A(5,5)=kf;
    A(6,7)=kf;
    %---------------------------------------------------------------------------------------------
    %Definition of matrix C
    C(1,1)=1/2;
    C(1,2)=1/2;
    C(3,5)=1/2;
    C(3,6)=1/2;
    C(2,3)=1/(2*sin(thetam));
    C(2,4)=-C(2,3); %mistake in paper
    C(4,7)=1/(2*sin(thetaa));
    C(4,8)=-C(4,7);
    %---------------------------------------------------------------------------------------------
    %Definition of matrix B
    B(1,1)=cos(phi);
    B(1,2)=sin(phi);
    B(1,4)=-cos(phi-s2theta);
    B(1,5)=-sin(phi-s2theta);
    B(2,1)=-B(1,2);
    B(2,2)=B(1,1);
    B(2,4)=-B(1,5);
    B(2,5)=B(1,4);
    B(3,3)=1;
    B(3,6)=-1;
    B(4,1)=2*CONVERT2*ki;
    B(4,4)=-2*CONVERT2*kf;
    %---------------------------------------------------------------------------------------------
    %Definition of matrix S
    Sinv=blkdiag(bshape,mshape,sshape,ashape,dshape); %S-1 matrix        
    S=Sinv^(-1);
    %---------------------------------------------------------------------------------------------
    %Definition of matrix T
    T(1,1)=-1/(2*L0);  %mistake in paper
    T(1,3)=cos(thetam)*(1/L1-1/L0)/2;
    T(1,4)=sin(thetam)*(1/L0+1/L1-2/(monorh*sin(thetam)))/2;
    T(1,6)=sin(thetas)/(2*L1);
    T(1,7)=cos(thetas)/(2*L1);
    T(2,2)=-1/(2*L0*sin(thetam));
    T(2,5)=(1/L0+1/L1-2*sin(thetam)/monorv)/(2*sin(thetam));
    T(2,8)=-1/(2*L1*sin(thetam));
    T(3,6)=sin(thetas)/(2*L2);
    T(3,7)=-cos(thetas)/(2*L2);
    T(3,9)=cos(thetaa)*(1/L3-1/L2)/2;
    T(3,10)=sin(thetaa)*(1/L2+1/L3-2/(anarh*sin(thetaa)))/2;
    T(3,12)=1/(2*L3);
    T(4,8)=-1/(2*L2*sin(thetaa));
    T(4,11)=(1/L2+1/L3-2*sin(thetaa)/anarv)/(2*sin(thetaa));
    T(4,13)=-1/(2*L3*sin(thetaa));
    %---------------------------------------------------------------------------------------------
    %Definition of matrix D
    % Lots of index mistakes in paper for matix D
    D(1,1)=-1/L0;
    D(1,3)=-cos(thetam)/L0;
    D(1,4)=sin(thetam)/L0;
    D(3,2)=D(1,1);
    D(3,5)=-D(1,1);
    D(2,3)=cos(thetam)/L1;
    D(2,4)=sin(thetam)/L1;
    D(2,6)=sin(thetas)/L1;
    D(2,7)=cos(thetas)/L1;
    D(4,5)=-1/L1;
    D(4,8)=-D(4,5);
    D(5,6)=sin(thetas)/L2;
    D(5,7)=-cos(thetas)/L2;
    D(5,9)=-cos(thetaa)/L2;
    D(5,10)=sin(thetaa)/L2;
    D(7,8)=-1/L2;
    D(7,11)=-D(7,8);
    D(6,9)=cos(thetaa)/L3;
    D(6,10)=sin(thetaa)/L3;
    D(6,12)=1/L3;
    D(8,11)=-D(6,12);
    D(8,13)=D(6,12);
 %---------------------------------------------------------------------------------------------
    %Definition of resolution matrix M
    if method==1 || strcmpi(method, 'Popovici')
        Minv=B*A*inv(inv(D*inv(S+T'*F*T)*D')+G)*A'*B'; %Popovici
    else
        HF=A*inv(G+C'*F*C)*A';
        %Horizontally focusing analyzer if needed
        % TODO: FIX removed as CN has no focusing, and it scrambles M
        if horifoc>0 && 0
            HF=HF^(-1);
            HF(5,5)=(1/(kf*alpha(3)))^2; 
            HF(5,4)=0; 
            HF(4,5)=0; 
            HF(4,4)=(tan(thetaa)/(etaa*kf))^2;
            HF=inv(HF);
        end
        Minv=B*HF*B'; %Cooper-Nathans
    end;

    % TODO: FIX added factor 5.545 from ResCal5
    M=5.545*inv(Minv);  % Correction factor 8*log(2) as input parameters
                        % are expressed as FWHM.

    % TODO: rows-columns 3-4 swapped for ResPlot to work. 
    % Inactivate as we want M=[x,y,z,E]
%    RM_(1,1)=M(1,1);
%    RM_(2,1)=M(2,1);
%    RM_(1,2)=M(1,2);
%    RM_(2,2)=M(2,2);
%    
%    RM_(1,3)=M(1,4);
%    RM_(3,1)=M(4,1);
%    RM_(3,3)=M(4,4);
%    RM_(3,2)=M(4,2);
%    RM_(2,3)=M(2,4);
%    
%    RM_(1,4)=M(1,3);
%    RM_(4,1)=M(3,1);
%    RM_(4,4)=M(3,3);
%    RM_(4,2)=M(3,2);
%    RM_(2,4)=M(2,3);
    %---------------------------------------------------------------------------------------------
    %Calculation of prefactor, normalized to source
    Rm=ki^3/tan(thetam); 
    Ra=kf^3/tan(thetaa);
    if method==1
        R0_=Rm*Ra*(2*pi)^4/(64*pi^2*sin(thetam)*sin(thetaa))*sqrt( det(F)/det( (D*(S+T'*F*T)^(-1)*D')^(-1)+G)); %Popovici
    else
        R0_=Rm*Ra*(2*pi)^4/(64*pi^2*sin(thetam)*sin(thetaa))*sqrt( det(F)/det(G+C'*F*C)); %Cooper-Nathans
    end;
    %---------------------------------------------------------------------------------------------
    %Normalization to flux on monitor
    if moncor==1
        g=G(1:4,1:4);
        f=F(1:2,1:2);
        c=C(1:2,1:4);
        t(1,1)=-1/(2*L0);  %mistake in paper
        t(1,3)=cos(thetam)*(1/L1mon-1/L0)/2;
        t(1,4)=sin(thetam)*(1/L0+1/L1mon-2/(monorh*sin(thetam)))/2;
        t(1,7)=1/(2*L1mon);
        t(2,2)=-1/(2*L0*sin(thetam));
        t(2,5)=(1/L0+1/L1mon-2*sin(thetam)/monorv)/(2*sin(thetam));
        sinv=blkdiag(bshape,mshape,monitorshape); %S-1 matrix        
        s=sinv^(-1);
        d(1,1)=-1/L0;
        d(1,3)=-cos(thetam)/L0;
        d(1,4)=sin(thetam)/L0;
        d(3,2)=D(1,1);
        d(3,5)=-D(1,1);
        d(2,3)=cos(thetam)/L1mon;
        d(2,4)=sin(thetam)/L1mon;
        d(2,6)=0;
        d(2,7)=1/L1mon;
        d(4,5)=-1/L1mon;
        if method==1
            Rmon=Rm*(2*pi)^2/(8*pi*sin(thetam))*sqrt( det(f)/det((d*(s+t'*f*t)^(-1)*d')^(-1)+g)); %Popovici
        else
            Rmon=Rm*(2*pi)^2/(8*pi*sin(thetam))*sqrt( det(f)/det(g+c'*f*c)); %Cooper-Nathans
        end;
        R0_=R0_/Rmon;
        R0_=R0_*ki; %1/ki monitor efficiency
    end;
    %---------------------------------------------------------------------------------------------
    %Transform prefactor to Chesser-Axe normalization
    R0_=R0_/(2*pi)^2*sqrt(det(M));
    %---------------------------------------------------------------------------------------------
    %Include kf/ki part of cross section
    R0_=R0_*kf/ki;
    %---------------------------------------------------------------------------------------------
    % Take care of sample mosaic if needed 
    % [S. A. Werner & R. Pynn, J. Appl. Phys. 42, 4736, (1971), eq 19]
    if isfield(sample,'mosaic')
        etas = sample.mosaic*CONVERT1;
        etasv= etas;
        if isfield(sample,'vmosaic')
            etasv = sample.vmosaic*CONVERT1;
        end;
        % TODO: FIX changed RM_(4,4) and M(4,4) to M(3,3)
        R0_=R0_/sqrt((1+(q*etas)^2*M(3,3))*(1+(q*etasv)^2*M(2,2)));
        %Minv=RM_^(-1);
        Minv(2,2)=Minv(2,2)+q^2*etas^2;
        Minv(3,3)=Minv(3,3)+q^2*etasv^2;
        % TODO: FIX add 8*log(2) factor for mosaicities in FWHM
        M=5.545*inv(Minv);
    end;
    %---------------------------------------------------------------------------------------------
    %Take care of analyzer reflectivity if needed [I. Zaliznyak, BNL]
    if isfield(ana,'thickness')&isfield(ana,'Q')            
        KQ = ana.Q;
        KT = ana.thickness;
        toa=(taua/2)/sqrt(kf^2-(taua/2)^2);
        smallest=alpha(4);
        if alpha(4)>alpha(3) smallest=alpha(3); end;
        Qdsint=KQ*toa;
        dth=((1:201)/200).*sqrt(2*log(2))*smallest;
        wdth=exp(-dth.^2/2./etaa^2);
        sdth=KT*Qdsint*wdth/etaa/sqrt(2.*pi);
        rdth=1./(1+1./sdth);
        reflec=sum(rdth)/sum(wdth);
        R0_=R0_*reflec;
    end;
    %---------------------------------------------------------------------------------------------
    R0(ind)=R0_;
    RM(:,:,ind)=M(:,:);
end;%for





