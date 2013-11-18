function lut=LoadLUTs()

% function lut=LoadLUTs()
%
% a subfunction to handle data
% load Color Lookup Table Values to memory from LUT files
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2012-05-29 16:32:07 ban"

global config;

save_dir=fullfile(fileparts(which('Mcalibrator2')),'data',config.date);
color_str={'red','green','blue'};
lut=zeros(str2num(config.lutoutbit.name),3); %#ok

for ii=1:1:length(color_str)
  try
    tmplut=load(fullfile(save_dir,sprintf('%s.lut',color_str{ii})));
  catch %#ok
    lut=[];
    return
  end
  lut(:,ii)=tmplut(:,2);
  clear tmplut;
end

return
