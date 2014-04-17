function lut=LoadLUTs()

% Loads Color LookUpTables into memory to handle them in Mcalibrator2.
% function lut=LoadLUTs()
%
% a subfunction to handle data
% load Color Lookup Table Values to memory from LUT files
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2014-04-16 09:58:36 ban"

global config;

% load the measured LUTs
save_dir=fullfile(config.save_dir,config.date);
save_fname=fullfile(save_dir,sprintf('mcalibrator2_results_%s.mat',config.date));
try
  tmp=load(save_fname,'lut'); tmp=tmp.lut;
catch
  tmp=cell(3,1);
end

% construct CLUT for RGB phosphors
if isempty(tmp{1}) || isempty(tmp{2}) || isempty(tmp{3}) % if RGB CLUTs are not generated
  lut=[];
else
  lut=zeros(size(tmp{1},2),3,2); % row: LUT index, col: RGB, third: 1=video input, 2=luminance
  lut(:,:,1)=[tmp{1}(1,:)',tmp{2}(1,:)',tmp{3}(1,:)']; % video input values
  lut(:,:,2)=[tmp{1}(2,:)',tmp{2}(2,:)',tmp{3}(2,:)']; % the corresponding (linearlized) luminance values
end

return
