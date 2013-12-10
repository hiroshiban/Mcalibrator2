function errors=ifittest(varargin)
% errors=ifittest(test) : performs a self-test procedure of the iFit/iData package
%
% The test procedure includes:
% * unit   tests of Objects and Libraries
% * system tests of Applications and Scripts
% * doc    tets  from the Documentation/tutorials
%
%   A report of all test is displayed at the end, with a list of failures.
%
%  input:  test:     empty to perform all tests, or a test directory
%  output: errors:   list of errors, or empty when all is fine (MException).
%
% ex:     ifittest;
%         ifittest('Objects/iData')
%
% Version: $Revision: 1161 $
% See also iData, fminsearch, optimset, optimget, ifitmakefunc

% when no location is given, use mfile location directories
if nargin ==0, varargin={}; end

pwd_test = fileparts(which(mfilename));

if isempty(varargin)
  varargin = { pwd_test };
end

tests_list = {};
for index=1:length(varargin)
  % get file list recursively from getAllFiles (private, below)
  tests_list = [ tests_list{:} ;  getAllFiles(varargin{index}) ];
end

% execute iteratively all tests
% build wait bar from full test length
t0 = clock;
h = waitbar(0, 'iFit test: (close to Abort)', 'Name','iFit: test running...' );
set(h, 'HandleVisibility','off');
t=findall(h,'Type','text'); set(t,'Interpreter','none');

status      = cell(1,length(tests_list));
errors      = {};
test_length = 0; % number of tests executed
failed      = 0;

% for each file, evaluate it, and get result 'OK','FAILED' 
% or last error with line nb and file
for index=1:length(tests_list)
  
  [p,f,e] = fileparts(tests_list{index});
  if exist(f) ~= 2 || strcmp(f, mfilename) || ~strcmp(e, '.m')
    continue; % only for valid M-files
  end
  % set short name of test
  if strncmp(p, pwd_test, length(pwd_test))
    p = p((length(pwd_test)+2):end);
  end
  tests_list{index} = fullfile(p,f);
  try
    disp([ mfilename ': executing test ' tests_list{index} ' -------------------' ]);
    
    result= feval(f); % no input args, returns 0/FAILED or 1/OK
    if isnumeric(result)
      if result, 
        result = [ 'OK     ' f ]; 
      else 
        result = [ 'FAILED ' f ];
      end
    end
  catch exception
    if ~isempty(exception.stack),
      result = sprintf('ERROR  %s\t\t%s in %s:%i', ...
        f, exception.message, exception.stack(1).file, exception.stack(1).line);
    else
      result = sprintf('ERROR  %s\t\t%s', f, exception.message);
    end
    errors{end+1} = exception;
  end
  
  % store result and update wait bar
  status{index} = result;
  close all
  if length(tests_list) > 1
    if ~ishandle(h), break; end % user closed the wait bar -> abort tests
    waitbar(index/length(tests_list), h, ...
        [ 'iFit test: ' tests_list{index} ' (close to Abort)' ],...
        'Name','iFit: test running...');
    if any(strncmp(status{index},{'FAILE','ERROR'},5))
      if ishandle(h)
        set(h, 'Color','magenta');
      end
      failed = failed+1;
    end
  end
  test_length = test_length+1;
end
if ishandle(h), delete(h); end

% write report
disp(['Status          Test                        [' mfilename ']' ]);
disp( '------------------------------------------------------')
for index=1:length(tests_list)
  if ~isempty(status{index})
    fprintf(1, '%-40s %s\n', status{index},tests_list{index});
  end
end

ratio = 1-failed/test_length;
disp( '------------------------------------------------------')
if failed == 0
  fprintf(1,'Success ratio: %i %% (%i tests)\n', ceil(ratio*100), test_length);
else
  fprintf(1,'Success ratio: %i %% (%i/%i tests failed)\n', ceil(ratio*100), failed, test_length);
end
fprintf(1,'Test duration: %g [s]\n', etime(clock,t0));

% ==============================================================================
function fileList = getAllFiles(dirName)

  dirData  = dir(dirName);     %# Get the data for the current directory
  if isempty(dirData)
    % we try to prepend the ifittest location (relative path given)
    dirData = fullfile(fileparts(which(mfilename)), dirData);
  end
  dirIndex = [dirData.isdir];  %# Find the index for directories
  fileList = {dirData(~dirIndex).name}';  %'# Get a list of the files
  if ~isempty(fileList)
    fileList = cellfun(@(x) fullfile(dirName,x),...  %# Prepend path to files
                       fileList,'UniformOutput',false);
    fileList = fileList(~strcmp(fileList, mfilename)); % skip main test proc
  end
  subDirs = {dirData(dirIndex).name};  %# Get a list of the subdirectories
  validIndex = ~ismember(subDirs,{'.','..'});  %# Find index of subdirectories
                                               %#   that are not '.' or '..'
  for iDir = find(validIndex)                  %# Loop over valid subdirectories
    nextDir = fullfile(dirName,subDirs{iDir});    %# Get the subdirectory path
    fileList = [fileList; getAllFiles(nextDir)];  %# Recursively call getAllFiles
  end
  


