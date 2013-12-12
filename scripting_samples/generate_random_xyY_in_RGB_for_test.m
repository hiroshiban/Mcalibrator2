function xyY=generate_random_xyY_in_RGB_for_test(phosphors,num_xyY,flares,limits)

% Generates random xyY values for testing Mcalibrator2 functions (random values are generated in "RGB" space).
% function xyY=generate_random_xyY_in_RGB_for_test(phosphors,:num_xyY,:flares,:limits)
% (: is optional)
%
% This function generates random xyY values that are theoretically
% reproduceble by 'linear' summations of RGB values on the display
% device with 'phosphors' profile.
%
% [note]
% The difference between two similar functions,
% 1. generate_random_xyY_in_RGB_for_test : random values are generated in RGB color space.
%                                          the values tend to be aggregated around white, green and
%                                          blue region in xyY space (biased).
% 2. generate_random_xyY_in_xyY_for_test : random values are generated in xyY color space.
%                                          the values are generally fully randomized in xyY space
%                                          (no bias).
% For valid random sampling and measurement test, I recommend to use "generate_random_xyY_in_xyY_for_test."
% Two functions were once required for some test measurements of Mcalibrator2.
%
% [example]
% >> phosphors=[0.6544,0.3056,0.1501; 0.3224,0.6169,0.0390; 48.9632,168.9902,10.8905];
% >> num_xyY=50;
% >> flares=[];
% >> xyY=generate_random_xyY_for_test(phosphors,num_xyY,flares);
%
% [input]
% phosphors : phosphor xyY, [rx,gx,bx;ry,gy,by;rY,gY,bY] (RGB) at max voltage level of the display.
% num_xyY   : the number of xyY pairs you want to generate, 10 by default.
% flares    : flare xyY of the display (zero-level leakage of the light), [3(xyY) x 1] matrix.
%             empty (flares=[];) by default.
% limits    : limit of the generated xyY [x_lower,x_upper;y_lower,y_upper;Y_lower,Y_upper]
%             if NaN is set to a element, that part will be skipped for thresholding.
%             limits=NaN*zeros(3,2); (no limits) by default.
%
% [output]
% xyY       : the generated random CIE1931 xyY values. [3(xyY) x N] matrix.
%
%
% Created    : "2013-12-11 14:46:51 ban (ban.hiroshi@gmail.com)"
% Last Update: "2013-12-12 10:09:04 ban (ban.hiroshi@gmail.com)"

% check input variables.
if nargin<1, help(mfilename()); return; end
if nargin<2 || isempty(num_xyY), num_xyY=10; end
if nargin<3 || isempty(flares), flares=[]; end
if nargin<4 || isempty(limits), limits=NaN*zeros(3,2); end

if size(phosphors,1)~=3 || size(phosphors,2)~=3
  error('phosphors should be [rx,gx,bx;ry,gy,by;rY,gY,bY] (3x3) matrix. check input variable.');
end

if ~isempty(flares) && (size(flares,1)~=3 || size(flares,2)~=1)
  error('flares should be [x;y;Y] (3x1) matrix. check input variable.');
end

if size(limits,1)~=3 || size(limits,2)~=2
  error('limits should be [3(x,y,Y) x 2(lower,upper bounds)] matrix. check input variable.');
end

% update limits
limits(isnan(limits(:,1)),1)=-Inf;
limits(isnan(limits(:,2)),2)=Inf;

lowerbounds=repmat(limits(:,1),[1,num_xyY]);
upperbounds=repmat(limits(:,2),[1,num_xyY]);

% add path to Mcalibrator2 subfunctions
addpath(genpath(fullfile(pwd,'..','subfunctions')));

% generate directory to save the results
save_dir=fullfile(pwd,'results');
if ~exist(save_dir,'dir'), mkdir(save_dir); end

% initialize a random seed
InitializeRandomSeed();

% generate random xyY
fprintf('generating %d random xyY...',num_xyY);
rgb=unifrnd(0.0,1.0,[3,num_xyY]);
xyY=RGB2xyY(rgb,phosphors,flares);

% get outliers thresholding by limits
idx=find( xyY-lowerbounds<0 | upperbounds-xyY<0 );
[row,col]=ind2sub([3,num_xyY],idx);
idx=unique(col);

% modify the outliers
while numel(idx)>0
  % generate new xyY values for the outliers
  tmprgb=unifrnd(0.0,1.0,[3,numel(idx)]);
  rgb(:,idx)=tmprgb;
  xyY(:,idx)=RGB2xyY(tmprgb,phosphors,flares);

  % update the outlier index
  idx=find( xyY-lowerbounds<0 | upperbounds-xyY<0 );
  [row,col]=ind2sub([3,num_xyY],numel(idx));
  idx=unique(col);
end
disp('done.');

% record the generated xyY values to png and text files
tmpfnames=wildcardsearch(save_dir,'random_xyY_*.txt');
fid=fopen(fullfile(save_dir,sprintf('random_xyY_%02d.txt',length(tmpfnames)+1)),'w');
if fid==-1, error('can not open a text file to write. check input variable.'); end
for ii=1:1:size(xyY,2), fprintf(fid,'%.4f,%.4f,%.4f;\n',xyY(1,ii),xyY(2,ii),xyY(3,ii)); end
fclose(fid);

% plot the generated xyY values on CIE1931 diagram
new_fig_flg=1; tri_flg=1; color_flg=1; marker_type=1;
PlotCIE1931xy(xyY(1:2,:),phosphors,new_fig_flg,tri_flg,color_flg,marker_type);
set(gcf,'PaperPositionMode','auto');
print(gcf,fullfile(save_dir,sprintf('random_xyY_%02d.png',length(tmpfnames)+1)),'-dpng','-r0');

save(fullfile(save_dir,sprintf('random_xyY_%02d.mat',length(tmpfnames)+1)),'xyY','rgb','phosphors','flares','limits');

% remove path to Mcalibrato2 subfunctions
rmpath(genpath(fullfile(pwd,'..','subfunctions')));

return
