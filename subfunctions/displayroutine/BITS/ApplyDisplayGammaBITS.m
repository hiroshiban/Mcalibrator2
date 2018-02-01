function ApplyDisplayGammaBITS(gamma_table)

% Loads and sets BITS++ display gamma-table(s) using PTB Screen() function.
% function ApplyDisplayGammaBITS(:gamma_table)
% (: is optional)
%
% Loads gamma table(s) and sets it(them) on PTB engine
%
% [input]
% gamma_table : table(s) of gamma-corrected video input values (Color LookupTable).
%               256(8-bits) x 3(RGB) x 1(or 2,3,... when using multiple displays) matrix
%               or a *.mat file specified with a relative path format. e.g. '/gamma_table/gamma1.mat'
%               The *.mat should include a variable named "gamma_table".
%               if you use multiple (more than 1) displays and set 256x3x1 gamma-table, the same
%               table will be applied to all displays. if the number of displays and gamma tables
%               are different (e.g. you have 3 displays and 256x3x!2! gamma-tables), the last
%               gamma_table will be applied to the second and third displays.
%               if empty, normalized gamma table (repmat(linspace(0.0,1.0,256),3,1)) will be applied.
%
% [output]
% no output variable
%
%
% Created    : "12-08-22 02:52:30 ban"
% Last Update: "2013-12-04 15:50:24 ban"

% check input variable
if nargin<1 || isempty(gamma_table), gamma_table=(repmat(linspace(0.0,1.0,256),3,1))'; end

% load matlab matrix if the input gamma_table is a file.
if ischar(gamma_table)
  if ~exist(fullfile(pwd,gamma_table),'file'), error('can not find gamma table file. check inptu variable.'); end
  gamma_table=load(fullfile(pwd,gamma_table));
  gamma_table=gamma_table.gamma_table; % just to organize structure...
end

if size(gamma_table,1)==3 && size(gamma_table,2)==256, gamma_table=permute(gamma_table,[2,1,3]); end
if size(gamma_table,1)~=256 || size(gamma_table,2)~=3, error('gamma_table should be 256x3xN matrix. check input variable'); end

% first, we need to reset PTB own gamma table
ResetDisplayGammaBITS(1.0);

% get opened PTB window pointers
winPtrs=Screen('Windows');

% setting each of gamma tables to each of displays
if length(winPtrs)==1
  BitsPlusSetClut(0,gamma_table(:,:,1)); return
else
  for ii=1:1:length(winPtrs), BitsPlusSetClut(winPtrs(ii),gamma_table(:,:,min(ii,size(gamma_table,3)))); end
end

return
