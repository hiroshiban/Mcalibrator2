function linear_estimate=AutoColorEstimateLinear(rawxyY,myxyY,phosphors,flare_XYZ,lut,colorimeterhandler,displayhandler,options)

% Estimates the best RGB video input values to get the requested CIE1931 xyY, using recursive linear estimations with random sampling.
% function linear_estimate=AutoColorEstimateLinear(rawxyY,myxyY,phosphors,flare_XYZ,lut,colorimeterhandler,displayhandler,options)
%
% Estimate [R,G,B] values to produce xyY you want to display based on least-square estimation assuming piecewise linearity
%
% [input]
% rawxyY             : raw xyY you want, [3 x n] matrix
% myxyY              : your xyY after preprocessing (e.g. flare-correction), [3 x n] matrix
%                      if no preprocessing is applied, myxyY=rawxyY;
% phosphors          : phosphor xyY, [rx,gx,bx;ry,gy,by;rY,gY,bY] after preprocessing
% flare_XYZ          : flare XYZ, [X,Y,Z] !NOTE! not used now May 16 2012 Hiroshi Ban
% lut                : color lookup table, [n x 3(r,g,b)] matrix, set lut=[]; if you do not need to use LUTs
% colorimeterhandler : handle to an object to manipulate colorimeter
% displayhandler     : function handle to manipulate/display color window
% options            : options, structure with the parameters below
%                      .iteration --- the number of iterations of estimation
%                      .samples   --- the number of samples to estimate local tristimulus values (XYZ)
%                      .rmserror  --- rsm error threshold to stop the estimation
%                      .ss0       --- search space to estimate the local tristimulus values, from ss0-ss1
%                      .ss1
%
% [output]
% linear_estimate    : cell structure {n x 1}, holding the estimation results with the variables below
%                      .method --- 'LUT' or 'RGB
%                      .wanted_xyY
%                      .measured_xyY
%                      .residuals --- measured_xyY minus rawxyY
%                      .rms --- error
%                      .RGB --- RGB values for all the estimations
%                      .LUT --- lut index if .method='LUT'
%                      .final_xyY --- the final estimation of xyY
%                      .final_RGB --- the final estimation of RGB
%                      .final_LUT --- the final estimation of LUT
%
%
% Created    : "2012-04-12 10:08:56 ban"
% Last Update: "2013-12-11 17:37:19 ban (ban.hiroshi@gmail.com)"

% check input variables
if nargin<7, help(mfilename()); linear_estimate=[]; return; end

if nargin<8 || isempty(options)
  options.iteration=5;
  options.samples=18;
  options.rmserror=1; % percent error
  options.ss0=2.0; % search space, from ss0 to ss1
  options.ss1=1.0;
end

if ~isstructmember(options,'iteration'), options.iteration=5; end
if ~isstructmember(options,'samples'), options.samples=18; end
if ~isstructmember(options,'rmserror'), options.rmserror=1; end
if ~isstructmember(options,'ss0'), options.ss0=2.0; end
if ~isstructmember(options,'ss1'), options.ss1=1.0; end

% to store measured value
mxyY=zeros(3,options.iteration);

% to store local XYZ/RGB data samples to estimate a new transformation
% matrix by least squares, assuming piecewise linearity
sXYZ=zeros(3,options.samples);
sRGB=zeros(3,options.samples);
msXYZ=zeros(3,options.samples);

% output variable to store the results
linear_estimate=cell(size(myxyY,2),1);

% initialize color window
fig_id=displayhandler([255,255,255],1); pause(0.2);

%% least-square estimations of RGB values
for mm=1:1:size(myxyY,2)

  % initial transformation
  pXYZ0=xyY2XYZ(phosphors); % set the global phosphor XYZ matrix as initial values
  T0=inv(pXYZ0);

  % estimation of the transformation matrix
  % here, estimation is done in XYZ space, not in xyY, to make the estimation stable.
  % if we estimate in xyY space, the results will be distorted as Y is too large compared with the other values
  for ii=1:1:options.iteration

    % the first estimation of RGB values
    RGB0=T0*xyY2XYZ(myxyY(:,mm)); RGB0(RGB0<0)=0; RGB0(RGB0>1)=1;
    if ~isempty(lut), RGB0=getRGBfromLUT(lut,RGB0); end

    % Measuring CIE1931 xyY
    [YY,xx,yy,displayhandler,colorimeterhandler]=...
      MeasureCIE1931xyY(displayhandler,colorimeterhandler,RGB0,1,fig_id);

    % calculate error
    xyY0=[xx;yy;YY];
    XYZ0=xyY2XYZ(xyY0);
    eXYZ=abs(XYZ0-xyY2XYZ(rawxyY(:,mm))); % erorr in XYZ space

    % generate samples & measure
    ss=options.ss0+(ii-1)*(options.ss1-options.ss0)/(options.iteration-1);

    % get samples to estimate a new transformation matrix (local phosphor xyY),
    % assuming a piecewise linearity
    for rr=1:1:options.samples

      % generate local RGB data set
      sXYZ(:,rr)=xyY2XYZ(myxyY(:,mm))+unifrnd(-ss*eXYZ,ss*eXYZ);
      tmp=T0*sXYZ(:,rr); tmp(tmp<0)=0; tmp(tmp>1)=1;
      sRGB(:,rr)=tmp;
      if ~isempty(lut)
        RGB1=getRGBfromLUT(lut,sRGB(:,rr));
      else
        RGB1=sRGB(:,rr);
      end

      % Measuring CIE1931 xyY
      [YY,xx,yy,displayhandler,colorimeterhandler]=...
        MeasureCIE1931xyY(displayhandler,colorimeterhandler,RGB1,1,fig_id);

      sxyY=[xx;yy;YY];
      %msXYZ(:,rr)=xyY2XYZ(sxyY)-flare_XYZ;
      msXYZ(:,rr)=xyY2XYZ(sxyY);

    end % for rr=1:1:options.samples

    % estimate transformation from local samples acquired above by least-squares
    % MODEL: RGB' = XYZ'*T
    %        RGB = T'*XYZ
    % SOLUTION: T = inv(xXYZ*sXYZ')*sXYZ*sRGB'
    %T1=inv(msXYZ*msXYZ')*msXYZ*sRGB';
    T1=(msXYZ*msXYZ')\msXYZ*sRGB';
    T1=T1';

    % generate local phosphor RGB
    RGB2=T1*xyY2XYZ(myxyY(:,mm)); RGB2(RGB2<0)=0; RGB2(RGB2>1)=1;
    if ~isempty(lut), RGB2=getRGBfromLUT(lut,RGB2); end

    % Measuring CIE1931 xyY
    [YY,xx,yy,displayhandler,colorimeterhandler]=...
      MeasureCIE1931xyY(displayhandler,colorimeterhandler,RGB2,1,fig_id);

    % update the transformation matrix
    xyY1=[xx;yy;YY];
    mxyY(:,ii)=xyY1;
    T0=T1;

    % calculate RMS error
    e=(xyY1-rawxyY(:,mm))./rawxyY(:,mm)*100; % [%] error
    %e=(xyY2XYZ(xyY1)-xyY2XYZ(rawxyY(:,mm)))./xyY2XYZ(rawxyY(:,mm))*100; % [%] error
    rms=sqrt(e'*e);

    % store the data
    if ~isempty(lut)
      linear_estimate{mm}.method='LUT';
    else
      linear_estimate{mm}.method='RGB';
    end
    linear_estimate{mm}.wanted_xyY=rawxyY(:,mm);
    linear_estimate{mm}.measured_xyY(:,ii)=mxyY(:,ii);
    linear_estimate{mm}.residuals(:,ii)=mxyY(:,ii)-rawxyY(:,mm);
    linear_estimate{mm}.rms(ii)=rms;
    linear_estimate{mm}.RGB(:,ii)=RGB2;
    if ~isempty(lut)
      for nn=1:1:3
        [dummy,idx]=min(abs(lut(:,nn)-RGB2(nn)));
        linear_estimate{mm}.LUT(nn,ii)=idx;
      end
    end

    % break if rmserror reaches the criteria
    if rms<options.rmserror, break; end

  end % for ii=1:1:options.iteration

  [dummy,idx]=min(linear_estimate{mm}.rms);
  linear_estimate{mm}.final_xyY=linear_estimate{mm}.measured_xyY(:,idx);
  linear_estimate{mm}.final_RGB=linear_estimate{mm}.RGB(:,idx);
  if ~isempty(lut), linear_estimate{mm}.final_LUT=linear_estimate{mm}.LUT(:,idx); end

end % for mm=1:1:size(myxyY,1)

displayhandler(-999,1,fig_id);

return


%% subfunctions
function [rgb,lutidx]=getRGBfromLUT(lut,rgb)

lutidx=ceil(rgb.*size(lut,1));
lutidx(lutidx<=0)=1;
lutidx(lutidx>size(lut,1))=size(lut,1);
for nn=1:1:3, rgb(nn)=lut(lutidx(nn),nn); end

return
