function update_Mcalibrator2_docs()

% function update_Mcalibrator2_docs()
%
% This function updates html-based documents of Mcalibrator2
%
% [input]
% no input variable
%
% [output]
% New html-baesd documents will be generated in ~/doc/html.
% To read the document, please open ~/doc/html/index.html
% in your browser.
%
%
% Created    : "2011-11-02 11:31:48 banh"
% Last Update: "2013-12-11 09:18:47 ban (ban.hiroshi@gmail.com)"

% add path to m2html
m2htmlpath=fullfile(fileparts(mfilename('fullpath')),'utils','m2html');
addpath(m2htmlpath);

docpath=fullfile(fileparts(mfilename('fullpath')),'doc','html');
if exist(docpath,'dir'), rmdir(docpath,'s'); end

% generate html-based documents
disp('Updating Mcalibrator2 documents....');
disp(' ');

cd('..');
tgt_path={'Mcalibrator2',...
          'Mcalibrator2/scripting_samples',...
          'Mcalibrator2/subfunctions/colorcalculator',...
          'Mcalibrator2/subfunctions/colorimeter',...
          'Mcalibrator2/subfunctions/display_test',...
          'Mcalibrator2/subfunctions/displayroutine',...
          'Mcalibrator2/subfunctions/filter',...
          'Mcalibrator2/subfunctions/ifit-1.5',...
          'Mcalibrator2/subfunctions/lang',...
          'Mcalibrator2/subfunctions/mains',...
          'Mcalibrator2/subfunctions/transformation',...
          'Mcalibrator2/subfunctions/utils',...
          'Mcalibrator2/utils'};
m2html('mfiles',tgt_path,'htmldir',docpath,'recursive','on','globalHypertextLinks','on');
cd('Mcalibrator2');

disp(' ');
disp('completed.');

% remove path to m2html
rmpath(m2htmlpath);

return
