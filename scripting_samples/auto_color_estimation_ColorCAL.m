function estimate=auto_color_estimation_ColorCAL(xyY_want,lut,phosphors)

% A sample to run the recursive linear color estimation from your own script/function.
% function estimate=auto_color_estimation_ColorCAL(xyY_want,lut,:phosphors)
% (: is optional)
%
% A simple script to run the recursive-linear auto color calibration procedure developed
% by H.Ban and H.Yamamoto, using Cambridge Research Systems ColorCAL MK2 via a USB connection.
%
% The details of the algorithm is described in
% Ban, H., & Yamamoto, H. (2013).
% A non-device-specific approach to display characterization based on linear, nonlinear, and hybrid search algorithms.
% Journal of Vision, 13(6):20, 1-26, http://www.journalofvision.org/content/13/6/20, doi:10.1167/13.6.20.
%
% [how to use]
% 1. connect ColorCAL MK2 to computer with a USB cable
% 2. launch MATLAB (32-bit) and go to this directory
% 3. run the auto-calibration script on MATLAB
%    >> estimate=auto_color_estimation_ColorCAL(xyY_want,lut);
% 4. results is stored in 'auto_estimation_YYMMDD.mat' file
%
% [input]
% myxyY      : xyY values we want, [3 x n] matrix
% lut        : color lookup table, [n x 3(r,g,b)] matrix, set lut=[]; if you do not need to use LUTs
% phosphors  : phosphor xyY, [rx,gx,bx;ry,gy,by;rY,gY,bY] (RGB) at max voltage level of the display
%
% [output]
% stimate    : cell structure {n x 1}, holding the estimation results with the variables below
%              .method --- 'LUT' or 'RGB
%              .wanted_xyY
%              .measured_xyY
%              .residuals --- measured_xyY minus rawxyY
%              .rms --- error
%              .RGB --- RGB values for all the estimations
%              .LUT --- lut index if .method='LUT'
%              .final_xyY --- the final estimation of xyY
%              .final_RGB --- the final estimation of RGB
%              .final_LUT --- the final estimation of LUT
%
%
% Created    : "2013-12-11 13:15:17 ban"
% Last Update: "2013-12-12 12:36:32 ban"

% check input variables
if nargin<3, help(mfilename()); return; end

if size(xyY_want,1)~=3, error('xyY_want shold be [3(x,y,Y) x n] matrix. check input variable.'); end
if size(lut,2)==1, lut=repmat(lut,1,3); end
if size(phosphors,1)~=3 || size(phosphors,2)~=3, error('phosphors should be [rx,gx,bx;ry,gy,by;rY,gY,bY](3 x 3) matrix. check input variable.'); end

% if lut is empty, generating a linear one
if isempty(lut), lut=repmat(linspace(0.0,1.0,256),[3,1])'; end

% add path to Mcalibrator2 subfunctions
addpath(genpath(fullfile(pwd,'..','subfunctions')));

% generate directory to save the results
save_dir=fullfile(pwd,'results');
if ~exist(save_dir,'dir'), mkdir(save_dir); end

% initialize ColorCAL
device=colorcal;
device=device.gen_port();
device=device.initialize();

% set display handler
displayhandler=@DisplayColorWindow;

% set options for the recursive linear estimation of RGB video inputs to produce your xyY values
options.iteration=5;
options.samples=18;
options.rsmerror=1; % percent error. the estimation will be terminated when the error is less than this value.
options.ss0=2.0; % search space, from ss0 to ss1
options.ss1=1.0;

% run the recursive linear estimation
% you can also select one from the other algorithms implemented in Mcalibrator2 or your own procedures.
fprintf('optimizing RGB video inputs to produce xyY you want...');
estimate=AutoColorEstimateLinear(xyY_want,xyY_want,phosphors,[],lut,device,displayhandler,options);
disp('done.');

% plotting
fprintf('Plotting estimated accuracies on the CIE1931 diagram...');
PlotCIE1931xy([],phosphors,-1,0,1);
for mm=1:1:size(xyY_want,2)
  hold on;
  PlotCIE1931xy(xyY_want(1:2,mm),phosphors,0,1,1,1);
  PlotCIE1931xy(estimate{mm}.final_xyY(1:2),phosphors,0,1,1,0);
end
disp('done.');

% save the measurement resutls
fprintf('saving the results...');
savefname=fullfile(save_dir,sprintf('auto_estimation_%s.mat',datestr(now,'yymmdd')));
save(savefname,'estimate');
disp('done.');

% remove path to Mcalibrato2 subfunctions
rmpath(genpath(fullfile(pwd,'..','subfunctions')));

return
