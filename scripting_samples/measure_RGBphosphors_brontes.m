function [Phosphor,white,flare,mcolors,mcolors_str]=measure_RGBphosphors_brontes(out_fname,integtime,nrepeat)

% A sample to measure CIE1931 xyY for RGB video input values from your own script/function.
% function [Phosphor,white,flare,mcolors,mcolors_str]=measure_RGBphosphors_brontes(:out_fname,:integtime,:nrepeat)
% (: is optional)
%
% A simple script to measure RGB phosphor chromaticities (at the maximum voltage level)
% using Admesy brontes-LL photometer through a USB connection.
%
% [how to use]
% 1. connect Brontes-LL to computer with a USB cable
% 2. launch MATLAB (32-bit) and go to this directory
% 3. run the measurement script on MATLAB
%    >> measure_RGBphosphors_brontes('your_output_file_name')
% 4. results is stored in 'your_output_file_name' file
%
% [input]
% out_fname  : output file name, e.g. 'left_projector.mat', 'phosphor.mat' by default
% integtime  : integration time in usec, 20000 by default
% nrepeat    : the number of repetitions, 5 by default
%
% [output]
% Phosphor   : RGB phosphor xyY, 3x3 matrix. [Rx,Gx,Bx;Ry,Gy,By;RY,GY,BY]
% white      : CIE1931 xyY for white (RGB=[255,255,255]), [wx;wy;wY]
% flare      : CIE1931 xyY for black (RGB=[  0,  0,  0]), [kx;ky;kY]
% mcolors={[1,0,0],[0,1,0],[0,0,1],[1,1,1],[0,0,0]}; (fixed in this function for simplicity)
% mcolors_str={'red  ','green','blue ','white','black'}; (fixed in this function for simplicity)
%
% [note on chromaticity unit conversion]
%
% Once you get phosphor (and white & flare) matrix, you can convert RGB video input values
% to the corresponding CIE1931 xyY (XYZ, Lab, uv) chromaticity values.
% (To do chromatictiy unit conversion, add path to 'subfunction' directory first)
%
% For example, when the target pixel RGB values are RGB=[255,100,64],
%
% 1. to convert RGB pixel values to CIE1931 xyY
% >> xyY = RGB2xyY(RGB./255,Phosphor,[]); % recommended
% or
% >> xyY = RGB2xyY(RGB./255,Phosphor,flare);
%
% 2. to convert xyY to XYZ
% >> XYZ = xyY2XYZ(xyY);
%
% 3. to convert XYZ to Lab (using a Psychtoolbox function)
% >> Lab = lab=XYZToLab(XYZ,xyY2XYZ(white));
%
% 4. to convert xy to uv (using a Psychtoolbox function)
% >> xy = xyY(1:2);
% >> uv = xyTouv(xy,0);
%
%
% Created    : "2012-10-31 16:15:32 ban"
% Last Update: "2013-12-11 16:31:07 ban"

% check input variable
if nargin<1 || isempty(out_fname), out_fname='phosphor.mat'; end
if nargin<2 || isempty(integtime), integtime=20000; end
if nargin<3 || isempty(nrepeat), nrepeat=5; end

if ~strcmp(out_fname(end-3:end),'.mat'), out_fname=[out_fname,'.mat']; end

% add path to Mcalibrator2 subfunctions
addpath(genpath(fullfile(pwd,'..','subfunctions')));

% generate directory to save the results
save_dir=fullfile(pwd,'results');
if ~exist(save_dir,'dir'), mkdir(save_dir); end

% initialize Brontes-LL
device=brontesLL;
device=device.gen_port('USB0::0x1781::0x0E98::00032::INSTR');
device=device.initialize(integtime);

% display color window for adjusting colorimeter position
fullscr_flg=1;
fig_id=DisplayColorWindow(999,fullscr_flg);

disp(' ');
disp('*******************************************************************');
disp('adjust colorimeter position and press OK, then press F5 to proceed.');
disp('*******************************************************************');
disp(' ');
keyboard;

% measure RGB
mcolors={[1,0,0],[0,1,0],[0,0,1],[1,1,1],[0,0,0]};
mcolors_str={'red  ','green','blue ','white','black'};
Y=zeros(nrepeat,length(mcolors)); x=zeros(nrepeat,length(mcolors)); y=zeros(nrepeat,length(mcolors));
fprintf('\nmeasuring display chromaticities...\n\n');
for nn=1:1:nrepeat
  for cc=1:1:length(mcolors)
    fig_id=DisplayColorWindow(mcolors{cc},fullscr_flg,fig_id);
    [qq,Y(nn,cc),x(nn,cc),y(nn,cc),device]=device.measure(integtime);
  end
end

% display measured values
Y=mean(Y,1); x=mean(x,1); y=mean(y,1);
for cc=1:1:length(mcolors)
  fprintf('%s: CIE1931 xyY = (%f,%f,%f)\n',mcolors_str{cc},x(cc),y(cc),Y(cc));
end

% close color window and release a persistent variable to control figure
DisplayColorWindow(-999,fullscr_flg,fig_id);

% RGB phosphor chromaticity, [Rx Gx Bx; Ry Gy By; RY GY BY]
Phosphor=[x(1),x(2),x(3);y(1),y(2),y(3);Y(1),Y(2),Y(3)];

% plotting measured xy values in CIE1931 chromaticity diagram
new_fig_flg=1; tri_flg=1; color_flg=1; marker_type=1;
PlotCIE1931xy([x(4);y(4)],Phosphor,new_fig_flg,tri_flg,color_flg,marker_type);
white=[x(4);y(4);Y(4)];
flare=[x(5);y(5);Y(5)];

% save the measured resutls
fprintf('saving the results...');
save(fullfile(save_dir,out_fname),'Phosphor','white','flare','mcolors','mcolors_str');
disp('done.');

% remove path to Mcalibrato2 subfunctions
rmpath(genpath(fullfile(pwd,'..','subfunctions')));

return
