function [lut,xyY]=gamma_correction_ColorCAL(mes_steps,fit_method,num_repeats)

% A sample script to perform display gamma-correction by yourself without Mcalibrator2 GUI window.
% function [lut,xyY]=gamma_correction_ColorCAL(:mes_steps,:fit_method,:num_repeats)
% (: is optional)
%
% A simple script to perform display gamma-correction (grayscale only) using
% Cambridge Research Systems ColorCAL MK2 via a USB connection.
% When you customize the sub-routine to display color patches (DisplayColorWindow),
% you can interact with Psychtoolbox, ViSaGe, or BITS#.
%
% [how to use]
% 1. connect ColorCAL MK2 to computer with a USB cable
% 2. launch MATLAB (32-bit) and go to this directory
% 3. run the gamma-correction script on MATLAB
%    >> lut=gamma_correction_ColorCAL(32)
% 4. results is stored in 'gamma_correction_YYMMDD.mat' file
%
% [input]
% mes_steps   : measurement steps. 32 by default.
%               luminance measurement will be performed for video input values
%               defined by linspace(0.0,1.0,mes_steps)
% fit_method  : method to create gamma table, 'cbs' by default.
%               one of 'gog','cbs','rcbs','pow','pow2','log','lin', 'poly', 'sig', or 'sg'
%               currently, supported methods are
%               'gog'  : gain-offset-gamma model, exponential, based on CRT's internal model
%               'cbs'  : cubic spline
%               'rcbs' : robust cubic spline
%               'pow'  : power function
%               'pow2' : diff of 2 power functions
%               'log'  : 5th order polynomial fit in log space
%               'lin'  : linear interpolation
%               'poly' : 5th order polynomial fit
%               'sig'  : sigmoid function
%               'wbl'  : Weibull function
%               'gs'   : grid search with robust spline
%                        only valid when numluttbl==length(lum)
%               'gog (gain-offset-gamma model)' by default
%               'cbs (cubic spline)' is also recommneded if the display is LCD, DLP, or EL
%               For details, please see ApplyGammaCorrection.m
% num_repeats : the number of repetitions of the measurements, 1 by default.
%
% [output]
% lut        : the generated Color LookupTable. [1 x 256] matrix.
% xyY        : measured xyY values for each of video input intensities.
%              [4(video input value, x, y, Y) x mes_step] matrix.
%
%
% Created    : "2012-10-31 16:15:32 ban"
% Last Update: "2013-12-18 11:15:35 ban"

% check input variables
if nargin<1 || isempty(mes_steps), mes_steps=32; end
if nargin<2 || isempty(fit_method), fit_method='cbs'; end
if nargin<3 || isempty(num_repeats), num_repeats=1; end

% add path to Mcalibrator2 subfunctions
addpath(genpath(fullfile(pwd,'..','subfunctions')));

% generate directory to save the results
save_dir=fullfile(pwd,'results');
if ~exist(save_dir,'dir'), mkdir(save_dir); end

% initialize ColorCAL
device=colorcal;
device=device.gen_port();
device=device.initialize();

% display color window for adjusting colorimeter position
fullscr_flg=1;
fig_id=DisplayColorWindow(999,fullscr_flg);

disp(' ');
disp('*******************************************************************');
disp('adjust colorimeter position and press OK, then press F5 to proceed.');
disp('*******************************************************************');
disp(' ');
keyboard;

% set colors and mask
colors={'red','green','blue','gray'};
colormask={[1,0,0],[0,1,0],[0,0,1],[1,1,1]};

% initializing xyY data structure
xyY=cell(length(colors),1);
for ii=1:1:length(colors)
  xyY{ii}=zeros(4,mes_steps); % 4 = video-input-values, CIE1931 x, CIE1931 y, and CIE1931 Y.
  xyY{ii}(1,:)=linspace(0.0,1.0,mes_steps);
end

% light measurements, alternatively you can use MeasureCIE1931xyYs function implemented in Mcalibrator2.
for ii=1:1:length(colors)
  fprintf('measuring luminance/chromaticity for %s...',colors{ii});
  tmpx=zeros(num_repeats,mes_steps); tmpy=zeros(num_repeats,mes_steps); tmpY=zeros(num_repeats,mes_steps);
  for rr=1:1:num_repeats
    for nn=1:1:mes_steps
      fig_id=DisplayColorWindow(repmat(xyY{ii}(1,nn),1,3).*colormask{ii},fullscr_flg,fig_id);
      [dummy,tmpY(rr,nn),tmpx(rr,nn),tmpy(rr,nn),device]=device.measure();
    end
  end
  xyY{ii}(2:4,:)=[mean(tmpx,1);mean(tmpy,1);mean(tmpY,1)];
  clear tmpx tmpy tmpY;
  disp('done.');
end

% close color window and release a persistent variable to control figure
DisplayColorWindow(-999,fullscr_flg,fig_id);

% apply gamma-correction to the measured data
lutnum=256; monotonic_flg=1; lowpass_flg=0; flare_correction_flg=1; display_flg=1; save_flg=0;
lut=cell(length(colors),1);
for ii=1:1:length(colors)
  fprintf('generating gamma-table for %s...',colors{ii});
  lut{ii}=ApplyGammaCorrection(xyY{ii}([1,4],:),fit_method,lutnum,monotonic_flg,lowpass_flg,flare_correction_flg,display_flg,save_flg);
  movefile(fullfile(pwd,sprintf('gamma_corr_result_%s.png',fit_method)),...
           fullfile(save_dir,sprintf('gamma_corr_result_%s_%s.png',fit_method,colors{ii})));
  disp('done.');
end

% save phosphor xyY as [rx,gx,bx;ry,gy,by;rY,gY,bY]
phosphors=[xyY{1}(2:4,end),xyY{2}(2:4,end),xyY{3}(2:4,end)];

% save the measurement resutls
fprintf('saving the data...');
savefname=fullfile(save_dir,sprintf('gamma_correction_%s.mat',datestr(now,'yymmdd')));
save(savefname,'colors','colormask','lut','xyY','phosphors');
disp('done.');

% remove path to Mcalibrator2 subfunctions
rmpath(genpath(fullfile(pwd,'..','subfunctions')));

return
