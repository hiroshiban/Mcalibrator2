function lut=LoadLUTs()

% Loads Color LookUpTable into memory to handle it in Mcalibrator2.
% function lut=LoadLUTs()
%
% a subfunction to handle data
% load Color Lookup Table Values to memory from LUT files
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2013-12-11 17:20:15 ban (ban.hiroshi@gmail.com)"

global config;

save_dir=fullfile(config.save_dir,config.date);
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
