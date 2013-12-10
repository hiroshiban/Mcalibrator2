function result = looktxt(varargin)
% result = looktxt(file, options, ...)
%
% Action: Search and export numerics in a text/ascii file.
% This program analyses files looking for numeric parts
% Each identified numeric field is named and exported
% into an output filename.

%     export MATLABROOT=/opt/MATLAB/R2010a
%     export ARCH=glnxa64
%     export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$MATLABROOT/bin/$ARCH:$MATLABROOT/sys/os/$ARCH
%     gcc -I$MATLABROOT/extern/include -L$MATLABROOT/bin/$ARCH -DUSE_MAT -O2 -o looktxt -lmat -lmx looktxt.c

% this function is called when the MeX is not present/compiled

persistent compiled

result = [];

this_path = fileparts(which(mfilename));

% check if we use the looktxt executable, or need to compile the MeX (only once)
if ~isdeployed && (isempty(compiled) || ( length(varargin) == 1 && strcmp(varargin{1}, 'compile') ) )
  compiled = 0;
  
  % check if iLoad config allows MeX
  config = iLoad('config');
  if isfield(config, 'MeX') && ...
   ((isfield(config.MeX, mfilename) && strcmp(config.MeX.(mfilename), 'yes')) ...
     || strcmp(config.MeX, 'yes'))
    % attempt to compile MeX
    fprintf(1, '%s: compiling mex...\n', mfilename);
    try
      cmd={'-O','-output',fullfile(this_path,mfilename), ...
           fullfile(this_path,'looktxt.c'),'-DUSE_MEX'};
      disp([ 'mex ' sprintf('%s ', cmd{:}) ]);
      mex(cmd{:});
      compiled = 1;
    catch
      try
        cmd={'-O','-output',fullfile(this_path,mfilename),...
             fullfile(this_path,'looktxt.c'),'-DUSE_MEX', ...
             ['-L"' fullfile(matlabroot,'sys','lcc','lib') '"' ],'-lcrtdll'};
        disp([ 'mex ' sprintf('%s ', cmd{:}) ]);
        mex (cmd{:});
        compiled = 2;
      catch
        compiled = 0;
        error('%s: Can''t compile looktxt.c mex\n       in %s\n', ...
          mfilename, fullfile(this_path));
      end
    end
    if compiled
      rehash
      % rethrow cif2hkl command with new MeX
      clear functions
      if exist(mfilename) == 3
        result = looktxt(varargin{:});
      elseif nargin > 0
        error('%s: MeX compiled successfully. Rethrow command to use it.');
      end
    end
    return
  elseif isempty(dir(fullfile(this_path,mfilename))) % no executable available
    % attempt to compile as binary
    fprintf(1, '%s: compiling binary...\n', mfilename);
    try
      cmd={'-f', fullfile(matlabroot,'bin','matopts.sh'), '-DUSE_MAT', ...
           '-O', '-output', fullfile(this_path,mfilename), ...
           fullfile(this_path,'looktxt.c'), '-lmat', '-lmx'};
      disp([ 'mex ' sprintf('%s ', cmd{:}) ]);
      mex(cmd{:});
    catch
      error('%s: Can''t compile looktxt.c binary\n       in %s\n', ...
          mfilename, fullfile(this_path));
    end
  end
  cd(p)
end
if isempty(varargin) || strcmp(varargin{1}, 'compile'), return; end

% handle input arguments

% assemble command line
cmd = fullfile(this_path, mfilename);

cmd = [ cmd ' ' sprintf('%s ', varargin{:}) ];
disp(cmd)

% launch the command
[status, result] = system(cmd);



