function [lut,lumfiltered,flare,fit]=ApplyGammaCorrection(lum,method,numluttbl,monotonic_flg,lowpass_flg,flare_correction_flg,display_flg,save_flg,options)

% Applies gamma-correction to the measured luminance data and generates the corresponding Color LookUpTable.
% function [lut,lumfiltered,flare,fit]=...
%   ApplyGammaCorrection(lum,:method,:numluttbl,:monotonic_flg,:lowpass_flg,:flare_correction_flg,:display_flg,:save_flg,:options)
% (: is optional)
%
% Reads luminance values of the corresponding video input values,
% conducts gamma correction, and generate Color LookUp Table (CLUT).
% Most of the procedures used in this function are derived from the
% original Mcalibrator's first-level analysis source codes.
% Chromaticity constancy evaluation, and Automatic chromaticity
% adjustment procedures are not implemented in this function.
%
% [input]
% lum          : raw luminance values, [n x 2(graylevel,luminance)] or [2 x n] matrix
%                graylevel & the corresponding lum values should be sorted in ascending order in advance
% method       : method to create gamma table
%                one of 'gog','cbs','rcbs','pow','pow2','log','lin', 'poly', 'sig', or 'sg'
%                currently, supported methods are
%                'gog'  : gain-offset-gamma model, exponential, based on CRT's internal model
%                'cbs'  : cubic spline
%                'rcbs' : robust cubic spline
%                'pow'  : power function
%                'pow2' : diff of 2 power functions
%                'log'  : 5th order polynomial fit in log space
%                'lin'  : linear interpolation
%                'poly' : 5th order polynomial fit
%                'sig'  : sigmoid function
%                'wbl'  : Weibull function
%                'gs'   : grid search with robust spline
%                         only valid when numluttbl==length(lum)
%                'gog (gain-offset-gamma model)' by default
%                'cbs (cubic spline)' is also recommneded if the display is LCD, DLP, or EL
% numluttbl    : the number of elements in a CLUT table, 256 by default
%                should be set to 256 to create PTB's CLUT
% monotonic_flg: whether applying monotonic filter, [0|1], 1 by default
% lowpass_flg  : whether applying lowpass filter to the raw lum data, [0|1], 0 by default
% flare_correction_flg : whether applying flare correction to the raw lum data, [0|1], 1 by default
% display_flg  : whether displaying/saving gamma correction result figure, [0|1], 1 by default
% save_flg     : whether saving gamma correction result, [0|1], 0 by default
% options      : option parameters with 3 fields listed below
%               .lowpass_cutoff : cutoff frequencty of the lowpass filter, 0.085 by default.
%               .epsilon        : a cutoff value to be used in smoothing the data, 0.01 by default.
%               .breaks         : N-breaks of the data for robust spline, 8 (= 7 pieces) by default.
%
% [output]
% lut          : linearly corrected color lookup table
%                [2 (graylevel,luminance) x n (measurement)]
% lumfiltered  : filtered luminance values
% flare        : flare (leaked light), if flare_correction_flg=0, flare=0
% fit          : modeled luminance against video input values
%
%
% Created    : "2012-04-09 22:42:06 ban"
% Last Update: "2018-04-03 12:52:18 ban"

% check input variables
if nargin<1, help(mfilename()); lut=[]; return; end
if nargin<2 || isempty(method), method='gog'; end
if nargin<3 || isempty(numluttbl), numluttbl=256; end
if nargin<4 || isempty(monotonic_flg), monotonic_flg=1; end
if nargin<5 || isempty(lowpass_flg), lowpass_flg=0; end
if nargin<6 || isempty(flare_correction_flg), flare_correction_flg=1; end
if nargin<7 || isempty(display_flg), display_flg=1; end
if nargin<8 || isempty(save_flg), save_flg=0; end
if nargin<9 || isempty(options)
  options.lowpass_cutoff=0.085;
  options.epsilon=0.01;
  options.breaks=8;
end
if ~isstructmember(options,'lowpass_cutoff'), options.lowpass_cutoff=0.085; end
if ~isstructmember(options,'epsilon'), options.epsilon=0.01; end
if ~isstructmember(options,'breaks'), options.breaks=8; end

if ~strcmpi(method,'gog') && ~strcmpi(method,'cbs') && ~strcmpi(method,'rcbs') && ...
   ~strcmpi(method,'pow') && ~strcmpi(method,'pow2') && ~strcmpi(method,'log') && ...
   ~strcmpi(method,'lin') && ~strcmpi(method,'poly') && ~strcmpi(method,'sig') && ...
   ~strcmpi(method,'wbl') && ~strcmpi(method,'gs')
  error('supported methods are ''gog'',''cbs'',''rcbs'',''pow'',''pow2'',''log'',''lin'',''poly'',''sig'',''wbl'',''gs''. check input variables');
end

if strcmpi(method,'gs') && numluttbl~=length(lum)
  error('numluttbl and number of luminance measurement points should be same for grid search method. check input variables');
end

if monotonic_flg && lowpass_flg
  warning('currently, both monotonic_flg & lowpass_flg are on. it is recommended to set only one of these flags to 1'); %#ok
end

% initialize luminance input
%if size(lum,1)==length(lum), lum=lum'; end % set lum to [2(graylevel,luminance) x n] matrix
if size(lum,2)==2, lum=lum'; end % set lum to [2(graylevel,luminance) x n] matrix
org_lum=lum; % store the original data

% adjusting video input value range
%lum(1,:)=(lum(1,:)-lum(1,1))./(lum(1,end)-lum(1,1)); % assume the last value is max. %lum(1,:)=lum(1,:)./max(lum(1,:));
%lum(2,:)=100*lum(2,:); % temporal procedures, required for correct wrong luminance values

% applying monotonic increase filter
if monotonic_flg
  if display_flg, raw_lum=lum(2,:); end

  % step1, spline smoothing
  %lum(2,:)=smoothn(lum(2,:),'robust'); % robust constrain
  lum(2,:)=smoothn(lum(2,:));

  % step2, monotonic filter & test monotonic increase
  checkmono=0;
  while checkmono==0
    [lum(2,:),exitflag]=mc_ToMonotonic(lum(2,:));
    if exitflag==1 || exitflag==0, break; end
    checkmono=mc_CheckMonotoneIncrease(lum(2,:));
  end
end

% apply low-pass filtering
if lowpass_flg
  if display_flg && ~monotonic_flg, raw_lum=lum(2,:); end
  [b,a]=butter(1,options.lowpass_cutoff,'low'); % Nyquist frequency x 0.01 = cutoff frequency 5Hz
  lum(2,:)=filtfilt(b,a,lum(2,:)); % filtering with zero phase lag
end

% flare correction
if flare_correction_flg
  [lum(2,:),leaked_light,minlum_org,maxlum_org]=ApplyFlareCorrection(lum(2,:));
  maxlum=maxlum_org-minlum_org;
  minlum=0;
else
  maxlum=lum(2,end);
  minlum=lum(2,1); %0
end

% get the filtered luminance
lumfiltered=lum;
if flare_correction_flg
  flare=leaked_light;
else
  flare=zeros(1,size(lum,1));
end

% redundancy reductions for some methods
if strcmpi(method,'lin')
  if 128<=size(lum,2)
    lum_sparce=lum(:,1:3:end);
  else
    lum_sparce=lum;
  end
  idx=find(diff(lum_sparce(2,:))<=options.epsilon);
  lum_sparce(:,idx+1)=[];
  %if lum_sparce(1,end)~=1, lum_sparce=[lum_sparce,lum(:,end)]; end
  %if lum_sparce(1,1)~=0, lum_sparce=[lum(:,1),lum_sparce]; end
end

if strcmpi(method,'cbs')
  if 128<=size(lum,2)
    lum_sparce=lum(:,1:3:end);
  elseif 64<=size(lum,2) && size(lum,2)<128
    lum_sparce=lum(:,1:2:end);
  else
    lum_sparce=lum;
  end
  idx=find(diff(lum_sparce(2,:))<=options.epsilon);
  lum_sparce(:,idx+1)=[];
  %if lum_sparce(1,end)~=1, lum_sparce=[lum_sparce,lum(:,end)]; end
  %if lum_sparce(1,1)~=0, lum_sparce=[lum(:,1),lum_sparce]; end
end

if strcmpi(method,'log')
  lum_sparce=lum;
  idx=find(diff(lum_sparce(2,:))<=options.epsilon);
  lum_sparce(:,idx+1)=[];
  %if lum_sparce(1,end)~=1, lum_sparce=[lum_sparce,lum(:,end)]; end
  %if lum_sparce(1,1)~=0, lum_sparce=[lum(:,1),lum_sparce]; end
end

% fitting the model
if strcmpi(method,'gog')
  starting=1;
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByGamma,starting,options,lum,lum(1,:),lum(2,:));
  fprintf('******************************\n');
  fprintf('Display Gamma: %.4f\n',estimates);
  fprintf('******************************\n');
  fit=(lum(2,length(lum))-lum(2,1))*lum(1,:).^estimates+lum(2,1);
elseif strcmpi(method,'cbs')
  fit=spline(lum_sparce(1,:),lum_sparce(2,:),lum(1,:));
elseif strcmpi(method,'rcbs')
  % robust spline, here, 4 = piecewise cubic
  params=splinefit(lum(1,:),lum(2,:),options.breaks,4,'r');
  fit=ppval(params,lum(1,:));
elseif strcmpi(method,'pow')
  starting=[1,1,1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByPower1,starting,options,lum(1,:),lum(2,:));
  fit=estimates(1)*exp(-estimates(2)*lum(1,:))+estimates(3);
elseif strcmpi(method,'pow2')
  starting=[1,1,1,1,1,1,1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByPower2,starting,options,lum(1,:),lum(2,:));
  fit=estimates(1)*exp(-estimates(2)*(lum(1,:)-estimates(3)))-estimates(4)*exp(-estimates(5)*(lum(1,:)-estimates(6)))+estimates(7);
elseif strcmpi(method,'log')
  lumxlog=lum_sparce(1,:);
  lumylog=log10(lum_sparce(2,:));
  idx=find(isinf(lumylog));
  lumxlog(idx)=[];
  lumylog(idx)=[];
  Pr=polyfit(lumxlog,lumylog,5);
  fit=polyval(Pr,lum(1,:));
  fit=10.^fit;
elseif strcmpi(method,'lin')
  fit=interp1(lum_sparce(1,:),lum_sparce(2,:),lum(1,:),'linear');
elseif strcmpi(method,'poly')
  Pr=polyfit(lum(1,:),lum(2,:),5);
  fit=polyval(Pr,lum(1,:));
elseif strcmpi(method,'sig')
  starting=[1,0,0.1,0.1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumBySigmoid,starting,options,lum(1,:),lum(2,:));
  fit=estimates(1)*(lum(1,:)./estimates(3)).^estimates(4)./((lum(1,:)./estimates(3)).^estimates(4) + estimates(2));
elseif strcmpi(method,'wbl')
  starting=[1,1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByWeibull,starting,options,lum(1,:),lum(2,:));
  fit=1.0-exp( - ((lum(1,:)./ estimates(1)) .^ extimates(2)) );
elseif strcmpi(method,'gs')
  % just estimate value for robust spline
  if ~monotonic_flg
    % step1, spline fitting
    %fit=smoothn(lum(2,:),'robust'); % robust constrain
    fit=smoothn(lum(2,:));
    % step2, monotonic filter & test monotonic increase
    checkmono=0;
    while checkmono==0
      [fit,exitflag]=mc_ToMonotonic(fit);
      if exitflag==1 || exitflag==0, break; end
      checkmono=mc_CheckMonotoneIncrease(lum(2,:));
    end
  else
    fit=lum(2,:);
  end
end

% to monotonic
if monotonic_flg
  if find(diff(fit)<0)
    % monotonic increase filter
    checkmono=0;
    while checkmono==0
      [fit(1,:),exitflag]=mc_ToMonotonic(fit);
      if exitflag==1 || exitflag==0, break; end
      checkmono=mc_CheckMonotoneIncrease(fit);
    end
    tmp=fit; tmp(tmp<0)=0; fit=tmp;
  end
end

% initialize LUT related variables
interval=(maxlum-minlum)/(numluttbl-1);
lut=zeros(2,numluttbl);
lut(1,:)=(1:1:numluttbl)-1;
vals=min(fit)*ones(1,numluttbl-1);

% generating CLUT
if strcmpi(method,'gog')
  starting=1;
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByGamma,starting,options,lum,lum(1,:),lum(2,:));
  vals=( ((minlum:interval:maxlum)-minlum)./(maxlum-minlum) ).^(1./estimates);
  lut(2,:)=(lum(2,size(lum,2))-lum(2,1))*vals.^estimates+lum(2,1);
elseif strcmpi(method,'cbs')
  vals=spline(lum_sparce(2,:),lum_sparce(1,:),minlum:interval:maxlum);
  lut(2,:)=spline(lum(1,:),lum(2,:),vals);
elseif strcmpi(method,'rcbs')
  if monotonic_flg
    params=splinefit(fit,lum(1,:),round(length(lum)/2),4,'r');
    vals=ppval(params,minlum:interval:maxlum);
    params=splinefit(lum(1,:),fit,round(length(lum)/2),4,'r');
    lut(2,:)=ppval(params,vals);
  else
    % robust spline, here, 4 = piecewise cubic
    params=splinefit(fit,lum(1,:),options.breaks,4,'r');
    vals=ppval(params,minlum:interval:maxlum);
    params=splinefit(lum(1,:),fit,options.breaks,4,'r');
    lut(2,:)=ppval(params,vals);
  end
elseif strcmpi(method,'pow')
  starting=[1,1,1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByPower1,starting,options,lum(1,:),lum(2,:));
  vals=-(1/estimates(2))*log(((minlum:interval:maxlum)-estimates(3))./estimates(1));
  lut(2,:)=estimates(1)*exp(-estimates(2)*vals)+estimates(3);
elseif strcmpi(method,'pow2')
  starting=[1,1,1,1,1,1,1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByPower2,starting,options,lum(1,:),lum(2,:));
  % search method
  if lum(2,1)==0, lum(2,:)=lum(2,:)+0.1; end
  for B = 0:1:(size(lum,2)-1)
    repeat=0;
    while 1
      repeat=repeat+1;
      lut(2,B+1)=estimates(1)*exp(-estimates(2)*(vals(B+1)-estimates(3)))-estimates(4)*exp(-estimates(5)*(vals(B+1)-estimates(6)))+estimates(7);
      if repeat>10000 || ( ( (min(lum(2,:))+interval*B)*0.995 <= lut(2,B+1) ) && ( lut(2,B+1) <= (min(lum(2,:))+interval*B)*1.005) ) % error rate is within 0.05 %
        %fprintf(fid,'%03d %f\n',B,vals(B+1));
        break
      end
      vals(B+1)=vals(B+1) + 0.00010;
    end
    if B < size(lum,2)-1
      vals(B+2)=vals(B+1);
    end
  end
  if lum(2,1)==0.1, lum(2,:)=lum(2,:)-0.1; end
elseif strcmpi(method,'log')
  lumxlog=lum_sparce(1,:);
  lumylog=log10(lum_sparce(2,:));
  idx=find(isinf(lumylog));
  lumxlog(idx)=[];
  lumylog(idx)=[];
  Pr=polyfit(lumylog,lumxlog,5);
  vals=polyval(Pr,log10(minlum:interval:maxlum));
  Prt=polyfit(lumxlog,lumylog,5);
  Zr=polyval(Prt,vals);
  lut(2,:)=10.^Zr;
elseif strcmpi(method,'lin')
  vals=interp1(lum_sparce(2,:),lum_sparce(1,:),minlum:interval:maxlum,'linear');
  lut(2,:)=interp1(lum(1,:),lum(2,:),vals,'linear');
elseif strcmpi(method,'poly')
  Pr=polyfit(lum(2,:),lum(1,:),5);
  vals=polyval(Pr,minlum:interval:maxlum);
  Prt=polyfit(lum(1,:),lum(2,:),5);
  lut(2,:)=polyval(Prt,vals);
elseif strcmpi(method,'sig')
  starting=[1,0,0.1,0.1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumBySigmoid,starting,options,lum(1,:),lum(2,:));
  vals=estimates(1)*((minlum:interval:maxlum)./estimates(3)).^estimates(4)./(((minlum:interval:maxlum)./estimates(3)).^estimates(4) + estimates(2));
  lut(2,:)=estimates(3)*power( -vals*estimates(2)./(vals-estimates(1)), 1/estimates(4) );
elseif strcmpi(method,'wbl')
  starting=[1,1];
  options=optimset('Display','iter','TolX',1e-2);
  estimates=fminsearch(@mc_LumByWeibull,starting,options,lum(1,:),lum(2,:));
  vals=1.0-exp( - (((minlum:interval:maxlum)./ estimates(1)) .^ extimates(2)) );
  lut(2,:)=estimates(1)*power(-log(1-vals),1/estimates(2));
elseif strcmpi(method,'gs')
  tgtvals=linspace(fit(1),fit(end),numluttbl);
  for nn=1:1:numluttbl
    [dummy,idx]=min(abs(fit-tgtvals(nn)));
    vals(nn)=idx./numluttbl;
    lut(2,nn)=tgtvals(nn);
  end
end

% generate CLUT using the model curve fitted to the actual measurements
lut(1,:)=vals;

% filtering generated CLUT by robust spline when it does not monotonically increase
%if strcmpi(method,'cbs') || strcmpi(method,'poly') || strcmpi(method,'log') || strcmpi(method,'lin')
tmp=lut(1,:); tmp(tmp<org_lum(1,1))=org_lum(1,1); tmp(tmp>org_lum(1,end))=org_lum(1,end); lut(1,:)=tmp;
if find(diff(lut(1,:))<0)
  % spline smoothing
  %lut(1,:)=smoothn(lut(1,:),'robust'); % robust constrain
  lut(1,:)=smoothn(lut(1,:));
  % monotonic increase filter
  checkmono=0;
  while checkmono==0
    [lut(1,:),exitflag]=mc_ToMonotonic(lut(1,:));
    if exitflag==1 || exitflag==0, break; end
    checkmono=mc_CheckMonotoneIncrease(lut(1,:));
  end
  tmp=lut(1,:); tmp(tmp<org_lum(1,1))=org_lum(1,1); tmp(tmp>org_lum(1,end))=org_lum(1,end); lut(1,:)=tmp;
end

% put back corrected luminance to the actual values, required for correct wrong luminance values
if flare_correction_flg
  lut(2,:)=lut(2,:)+minlum_org;
  %lut(2,:)=lut(2,:)./100;
  maxlum=maxlum+minlum_org;
  minlum=minlum_org;
else
  maxlum=lum(2,end);
  minlum=0;
end

% plotting the results
if display_flg
  scrsz=get(0,'ScreenSize');
  f1=figure('Name',sprintf('Mcalibrator2 Gamma Correction Result: %s',method),...
            'NumberTitle','off',...
            'Position',[scrsz(3)/5,scrsz(4)/4,2*scrsz(3)/3,scrsz(4)/2]);

  subplot(3,4,[1:2,5:6]); hold on;
  if monotonic_flg || lowpass_flg
    lumline(1)=plot(org_lum(1,:),raw_lum,'go','LineWidth',1);
    lumline(2)=plot(org_lum(1,:),lum(2,:)+minlum,'bo','LineWidth',2);
    lumline(3)=plot(org_lum(1,:),fit+minlum,'r-','LineWidth',2);
    legend(lumline,{'measured','filtered','fitted'},'Location','SouthEast');
  else
    lumline(1)=plot(org_lum(1,:),lum(2,:)+minlum,'bo','LineWidth',2);
    lumline(2)=plot(org_lum(1,:),fit+minlum,'r-','LineWidth',2);
    legend(lumline,{'measured','fitted'},'Location','SouthEast');
  end
  xlabel('video input [0.0-1.0]');
  ylabel('luminance');
  set(gca,'XLim',[org_lum(1,1),org_lum(1,end)]);
  set(gca,'YLim',[minlum-2,maxlum+2]);
  if strcmpi(method,'gog') % update the axis tile with the estimated Gamma value.
    title(sprintf('gamma correction result, method: %s (Gamma: %.2f)',method,estimates));
  else
    title(sprintf('gamma correction result, method: %s',method));
  end

  subplot(3,4,[3:4,7:8]); hold on;
  lutline(1)=plot(1:1:numluttbl,lut(1,:),'mo-','LineWidth',2);
  set(gca,'XLim',[0,numluttbl+1]);
  set(gca,'YLim',[0,1]);
  xlabel('#lut ID');
  ylabel('video input [0.0-1.0]');
  legend(lutline,{'CLUT'},'Location','SouthEast');
  title(sprintf('gamma correction result, method: %s',method));

  subplot(3,4,9:10); hold on;
  %bar(org_lum(1,:),fit-lum(2,:),'FaceColor',[0,0,0]);
  bar(org_lum(1,:),fit-org_lum(2,:)+minlum,'FaceColor',[0,0,0]);
  set(gca,'XLim',[org_lum(1,1),org_lum(1,end)]); %set(gca,'XLim',[0,1]);
  xlabel('video input [0.0-1.0]');
  ylabel('residuals');
  title('residuals');

  subplot(3,4,11:12); hold on;
  plot(linspace(org_lum(1,1),org_lum(1,end),size(lut,2)),lut(2,:),'-','Color',[0,0,0]);
  set(gca,'XLim',[org_lum(1,1),org_lum(1,end)]); %set(gca,'XLim',[0,1]);
  xlabel('video input [0.0-1.0]');
  ylabel('luminance');
  title('RGB & Luminance');

  set(f1,'PaperPositionMode','auto');
  print(f1,sprintf('gamma_corr_result_%s.png',method),'-dpng','-r0');
  %saveas(f1,sprintf('gamma_corr_result_%s.png',method),'png');
end

% finishing
beepsnd=sin(2*pi*0.2*(0:900));
try % if this script can write data to sound device
  sound(beepsnd,22000);
catch %#ok
  % do nothing
end

% saving the result
if save_flg
  save_fname=sprintf('gamma_correction_%s_%s.mat',method,datestr(now,'yymmdd'));
  save(fullfile(pwd,save_fname),'lut','lum');
end

return


%% subfunctions

function [output,exitflag] = mc_ToMonotonic(input)

% June 10 2012, Hiroshi Ban

try
%if exist('lsqlin','file') % if optimization toolbox is installed

  % sophisticated, but not suitable for some luminance data
  % if some problems happened, use the codes below instead
  n = length(input);
  C = eye(n);
  D = input;
  A = diag(ones(n,1),0) - diag(ones(n-1,1),1);
  A(end,:) = [];
  b = zeros(n-1,1);
  
  opts = optimset('lsqlin');
  opts.LargeScale = 'on';
  opts.Display = 'none';
  opts.MaxIter=100;
  [output,dummy1,dummy2,exitflag] = lsqlin(C,D,A,b,[],[],[],[],[],opts);

catch
%else

  max_repeat=100
  [m,n] = size(input);
  output = input;
  checkmono = 0;
  repetition = 1;
  while checkmono==0 && repetition<=max_repeat
    for mm=1:1:m
      for nn=1:1:n-1
        if output(mm,nn)>output(mm,nn+1)
          if nn==1
            output(mm,nn)=2*output(mm,nn+1)-output(mm,nn+2);
          else
            output(mm,nn)=(output(mm,nn-1)+output(mm,nn+1))/2;
          end
        end
      end
    end

    % check the last & last-1 values, June 14 2008 by H.Ban
    for mm=1:1:m
      if output(m,end)<output(m,end-1)
        output(m,end)=2*output(m,end-1)-output(m,end-2);
      end
    end
    checkmono = mc_CheckMonotoneIncrease(output);
    fprintf('repetition: %03d/%03d',repetition,max_repeat);
    repetition=repetition+1;
  end

  if repetition>100
    exitflag=0;
  else
    exitflag=1;
  end

end % if ~exist('lsqlin','file') % if optimization toolbox is installed


function checkmono = mc_CheckMonotoneIncrease(output)

% June 10 2012, Hiroshi Ban

[m,n]=size(output);
resid=zeros(m,n-1);
for mm=1:1:m, resid(mm,:)=diff(output); end
idx=find(resid<0);
if ~isempty(idx)
  checkmono = 0;
else
  checkmono = 1;
end


function sse=mc_LumByGamma(params,Y,Input,Actual_Output)

% May 04 2004, Hiroshi Ban

gamma=params;
% Y should be 2xsamppoint matrix
% Y(1,:) sammppoint
% Y(2,:) measured luminance
cutoff = Y(2,1);
max = Y(2,length(Y));

Fitted_Curve=(max-cutoff)*Input.^gamma+cutoff;
Error_Vector=Fitted_Curve - Actual_Output;
% When curvefitting, a typical quantity to
% minimize is the sum of squares error
sse=sum(Error_Vector.^2);


function sse=mc_LumByPower1(params,Input,Actual_Output)

% May 04 2004, Hiroshi Ban

A=params(1);
lamda=params(2);
c=params(3);

Fitted_Curve=A.*exp(-lamda*Input)+c;
%Fitted_Curve=Input.^A;
Error_Vector=Fitted_Curve - Actual_Output;
% When curvefitting, a typical quantity to
% minimize is the sum of squares error
sse=sum(Error_Vector.^2);


function sse=mc_LumByPower2(params,Input,Actual_Output)

% May 04 2004, Hiroshi Ban

A=params(1);
lamda=params(2);
mu1=params(3);
B=params(4);
theta=params(5);
mu2=params(6);
c=params(7);

Fitted_Curve=A.*exp(-lamda*(Input-mu1))-B*exp(-theta*(Input-mu2))+c;
Error_Vector=Fitted_Curve - Actual_Output;
% When curvefitting, a typical quantity to
% minimize is the sum of squares error
sse=sum(Error_Vector.^2);


function sse=mc_LumBySigmoid(params,Input,Actual_Output)

% Sep 08 2011, Hiroshi Ban

%A=params(1);
%mu1=params(2);
%Fitted_Curve=A./(1+exp(-(Input-mu1)));

x(1)=params(1);
x(2)=params(2);
x(3)=params(3);
x(4)=params(4);

Fitted_Curve = x(1)*(Input./x(3)).^x(4)./((Input./x(3)).^x(4) + x(2));
Error_Vector=Fitted_Curve - Actual_Output;
% When curvefitting, a typical quantity to
% minimize is the sum of squares error
sse=sum(Error_Vector.^2);


function sse=mc_LumByWeibull(params,Input,Actual_Output)

% May 04 2012, Hiroshi Ban

alpha=params(1);
beta=params(2);

Fitted_Curve = 1.0 - exp( - ((Input./ alpha) .^ beta) );
Error_Vector=Fitted_Curve - Actual_Output;
% When curvefitting, a typical quantity to
% minimize is the sum of squares error
sse=sum(Error_Vector.^2);
