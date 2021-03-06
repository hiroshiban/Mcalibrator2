function lincoeff_estimate=AutoColorEstimateLinearCoeff(rawxyY,myxyY,phosphors,lut,colorimeterhandler,displayhandler,options)

% Estimates the best RGB video input values to get the requested CIE1931 xyY, using error adjusting method with a rate parameter.
% function lincoeff_estimate=AutoColorEstimateLinearCoeff(rawxyY,myxyY,phosphors,flare_XYZ,lut,colorimeterhandler,displayhandler,options)
%
% Estimate [R,G,B] values to produce xyY you want to display based on a simple adjustment
% by adding rgb_delta = CC*(T0*eXYZ) to rgb_measured (CC is a rate parameter, c<1.0).
% The optimization is just done by decreasing "CC".
%
% [details and ideas of this method] (Thanks a lot for suggestions from a annonymous reviewer of my paper)
% A reviewer's comment:
% I wonder if considerable efficiency could be obtained by adding a rather simple
% adjustment to the procedures. Suppose at some stage of the search process, we have
% our linear (global or local) matrix M that maps XYZ -> rgb. We have a current set
% of rgb values rgb_i and they produce a current measured output XYZ_i. We want to
% obtain XYZ_target. We can compute XYZ_delta = XYZ_target-XYZ_i. The linear model
% says that to correct for this error, we'd add rgb_delta = M*XYZ_delta to rgb_i.
% The linear model isn't exactly right, but I'm guessing it is often good enough to
% head things in the right direction. If rgb_delta is decreased by a rate parameter
% c < 1, this sort of update might home in very quickly on good rgb values.
% Perhaps even based on the global M.
%
% [input]
% rawxyY             : raw xyY you want, [3 x n] matrix
% myxyY              : your xyY after preprocessing (e.g. flare-correction), [3 x n] matrix
%                      if no preprocessing is applied, myxyY=rawxyY;
% phosphors          : phosphor xyY, [rx,gx,bx;ry,gy,by;rY,gY,bY] after preprocessing
% lut                : color lookup table, [n x 3(r,g,b)] matrix, set lut=[]; if you do not need to use LUTs
% colorimeterhandler : handle to an object to manipulate colorimeter
% displayhandler     : function handle to manipulate/display color window
% options            : options, structure generated by optimset function
%                      e.g. options=optimset('Display','off','TolX',1e-2);
%
% [output]
% lincoeff_estimate  : cell structure {n x 1}, holding the estimation results with the variables below
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
% Last Update: "2014-04-14 09:58:21 ban"

%% check input variables
if nargin<6, help(mfilename()); lincoeff_estimate=[]; return; end

if nargin<7 || isempty(options)
  options=optimset; % empty structure
  options.Display='iter';
  options.TolFun =1e-3;
  options.TolX   =1e-3;
  options.MaxIter=100;
  options.MaxFunEvals=200;
  options.Hybrid = 'Coggins';
  options.algorithm  = 'Powell Search (by Secchi) [ fminpowell ]';
  options.optimizer = 'fminpowell';
end

% set constrains
constrains.min=-2*ones(3,1);
constrains.max=2*ones(3,1);
constrains.fixed=zeros(3,1);
constrains.steps=0.1;

% output variable to store the results
lincoeff_estimate=cell(size(myxyY,2),1);

% initialize color window
fig_id=displayhandler([255,255,255],1); pause(0.2);

% initial transformation
pXYZ0=xyY2XYZ(phosphors); % set the global phosphor XYZ matrix as initial values
T0=inv(pXYZ0);

%% least-square estimations of RGB values
for mm=1:1:size(myxyY,2)

  % the first estimation of RGB values
  RGB0=T0*xyY2XYZ(myxyY(:,mm)); RGB0(RGB0<0)=0; RGB0(RGB0>1)=1;
  if ~isempty(lut), [dummy,RGB]=getLUTidx(lut,RGB0); end

  % Measuring CIE1931 xyY
  [YY,xx,yy,displayhandler,colorimeterhandler]=...
    MeasureCIE1931xyY(displayhandler,colorimeterhandler,RGB,1,fig_id);

  % calculate error
  xyY0=[xx;yy;YY];
  eXYZ=xyY2XYZ(xyY0)-xyY2XYZ(rawxyY(:,mm)); % erorr in XYZ space
  eRGB=T0*eXYZ;

  CC0=repmat(1.0,3,1); % a simple rate parameters to be optimized

  % Measuring & optimizing CIE1931 xyY
  CC=fminpowell(@estimate_CC,CC0,options,constrains,rawxyY(:,mm),RGB0,eRGB,displayhandler,colorimeterhandler,lut,fig_id);

  RGB=RGB0;
  deltaRGB=eRGB.*(CC)';
  if ~isempty(lut)
    lutidx=getLUTidx(lut,RGB);
    deltalutidx=sign(eRGB).*(ceil(abs(deltaRGB)*size(lut,1)));
    newlutidx=lutidx-deltalutidx;
    newlutidx(newlutidx<=0)=1;
    newlutidx(newlutidx>size(lut,1))=size(lut,1);
    for nn=1:1:3, RGB(nn)=lut(newlutidx(nn),nn); end
  else
    RGB=RGB+deltaRGB;
  end

  % check the accuracy of xyY for the optimized RGB values
  [YY,xx,yy,displayhandler,colorimeterhandler]=...
    MeasureCIE1931xyY(displayhandler,colorimeterhandler,RGB,1,fig_id);

  mxyY=[xx;yy;YY];

  % calculate RMS error
  e=(mxyY-rawxyY(:,mm))./rawxyY(:,mm)*100; % [%] error
  rms=sqrt(e'*e);

  % store the data
  if ~isempty(lut)
    lincoeff_estimate{mm}.method='LUT';
  else
    lincoeff_estimate{mm}.method='RGB';
  end
  lincoeff_estimate{mm}.wanted_xyY=rawxyY(:,mm);
  lincoeff_estimate{mm}.measured_xyY=mxyY;
  lincoeff_estimate{mm}.residuals=mxyY-rawxyY(:,mm);
  lincoeff_estimate{mm}.rms=rms;
  lincoeff_estimate{mm}.RGB=RGB;
  if ~isempty(lut)
    for nn=1:1:3
      [dummy,idx]=min(abs(lut(:,nn)-RGB(nn)));
      lincoeff_estimate{mm}.LUT(nn)=idx;
    end
  end
  lincoeff_estimate{mm}.final_xyY=lincoeff_estimate{mm}.measured_xyY;
  lincoeff_estimate{mm}.final_RGB=lincoeff_estimate{mm}.RGB;
  if ~isempty(lut), lincoeff_estimate{mm}.final_LUT=lincoeff_estimate{mm}.LUT; end

end % for mm=1:1:size(myxyY,1)

displayhandler(-999,1,fig_id);

return

% subfunction to do non-linear optimization
function sse=estimate_CC(params,wanted_xyY,RGB0,eRGB,displayhandler,colorimeterhandler,lut,fig_id)

% estimates CIE1931 xyY using a given transformation matrix
% params=[r;b;g]; or params=[lutRidx,lutGidx,lutBidx];

%% set variable
RGB=RGB0;
deltaRGB=eRGB.*(params)';
if ~isempty(lut)
  lutidx=getLUTidx(lut,RGB);
  deltalutidx=sign(eRGB).*(ceil(abs(deltaRGB)*size(lut,1)));
  newlutidx=lutidx-deltalutidx;
  newlutidx(newlutidx<=0)=1;
  newlutidx(newlutidx>size(lut,1))=size(lut,1);
  for nn=1:1:3, RGB(nn)=lut(newlutidx(nn),nn); end
  %fprintf('org(%03d,%03d,%03d), new(%03d,%03d,%03d)\n',lutidx(1),lutidx(2),lutidx(3),newlutidx(1),newlutidx(2),newlutidx(3));
else
  RGB=RGB+deltaRGB;
end

% measure CIE1931 xyY
[YY,xx,yy,displayhandler,colorimeterhandler]=...
  MeasureCIE1931xyY(displayhandler,colorimeterhandler,RGB,1,fig_id);

% calculate error
cxyY=[xx;yy;YY];

%% note: Though the error calculation here looks strange, I mean this fine.
%%       This is to match the criteria of error with linear transformation.
%%       If you want to calc the correct SSE, please use the first 2 lines.
%eXYZ=xyY2XYZ(cxyY)-xyY2XYZ(wanted_xyY);
%sse=eXYZ'*eXYZ;
exyY=(cxyY-wanted_xyY)./wanted_xyY.*100;
sse=sqrt(exyY'*exyY);

return
