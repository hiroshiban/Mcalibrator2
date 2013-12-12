function update_Mcalibrator2_docs()

% Generates/updates Mcalibrator2 html-based documents.
% function update_Mcalibrator2_docs()
%
% This function generates/updates html-based documents of Mcalibrator2
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
% Last Update: "2013-12-11 23:02:11 ban (ban.hiroshi@gmail.com)"

% add path to m2html
m2htmlpath=fullfile(fileparts(mfilename('fullpath')),'utils','m2html');
addpath(m2htmlpath);

docpath=fullfile(fileparts(mfilename('fullpath')),'doc','html');
if exist(docpath,'dir'), rmdir(docpath,'s'); end

% generate html-based documents
disp('Updating Mcalibrator2 documents....');
disp(' ');

cd('..');
tgt_path={'Mcalibrator2'};
m2html('mfiles',tgt_path,'htmldir',docpath,'recursive','on','globalHypertextLinks','on');
cd('Mcalibrator2');

disp(' ');
disp('completed.');

% remove path to m2html
rmpath(m2htmlpath);

return
