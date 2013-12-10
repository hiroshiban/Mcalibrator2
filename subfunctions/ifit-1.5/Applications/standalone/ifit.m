function ifit(varargin)
% Usage:  ifit [options] arguments commands 
%
%  iFit executable from command line.
%  Project page at <http://ifit.mccode.org>
%
%  arguments:
%    Any file name, including directories (imports all recursively).
%      Files can also be given as distant URLs (via http and ftp), and as compressed
%      content (zip, tar, gzip).
%      Script files (.m) are executed, other files are imported.
%    Any numerical value, including arrays given as e.g. '[ 1 2 ...]'.
%    The 'empty' argument is obtained from the '[]' argument
%    Any argument given between double quotes is used as a string argument.
%    Any argument given between simple quotes is evaluated as a an expression.
%
%  Once all arguments have been processed, they are stored in the 'this'
%    variable (cell array) for further use, and the program enters in interactive
%    mode except when the --exit argument is specified.
%  In interactive mode, any Matlab command can be entered if it spans on a single line.
%  To execute multiple lines and control statements (if/while/for...), write them
%    in a script and type 'run <script>'.
%
%  options:
%  --exit or -e
%      exits - should be specified after all other commands/arguments
%  --save or -s or --save=FILE
%      save the workspace variables when commands have been executed.
%  --run=SCRIPT or -r=SCRIPT
%      executes the SCRIPT when starting.
%
%  Examples:
%    ifit --save file1.*  subplot 

% Manual build:
% Better use the 'make.sh' script, or
% addpath(genpath('/home/farhi/svn/Matlab/iFit/trunk'))
% change all .m.org files into .m for the standalone
% mcc -m ifit -a /home/farhi/svn/Matlab/iFit/trunk
% buildmcr('.')

inline_display_banner; % see inline below

ifit_options.line     ='';     % the current line to execute
ifit_options.index    =1;      % the index of the input
this                  ={};     % the buffer from the command line
ifit_options.save     =0;

while ~strcmp(ifit_options.line, 'exit') && ~strcmp(ifit_options.line, 'return')
  ifit_options.line = strtrim(ifit_options.line);
  % handle specific commands (to override limitations from stand-alone)
  if strcmp(strtok(ifit_options.line,' '), 'doc')
    ifit_options.line = [ 'help' ifit_options.line(4:end) ];
    disp(ifit_options.line);
  end
  if strcmp(strtok(ifit_options.line,' ('),  'propedit')
    ifit_options.line = [ 'uiinspect' ifit_options.line(9:end) ];
  end
  if strcmp(strtok(ifit_options.line, ' ('), 'help')        % 'help' command ---------
    if length(ifit_options.line) > 4  % help <cmd>
      ifit_options.line = inline_display_helpcommand(ifit_options.line); % returns empty line
    else
      inline_display_help;            % see below (single 'help')
      ifit_options.line = 'doc(iData,''iFit''); disp('' '');';
    end
  elseif strncmp(ifit_options.line,'run ', 4) % 'run' command ------------------
    ifit_options.line = inline_runscript(ifit_options.line);
  elseif strncmp(ifit_options.line,'clear ', 5)% 'clear' must retain ifit_options and this
    ifit_options.line = [ 'clearvars ' ifit_options.line(6:end) ];
  end
  if strncmp(ifit_options.line,'clearvars ', 10)
    ifit_options.line = [ ifit_options.line ' -except ifit_options this' ];
  end
  if ~isempty(dir(ifit_options.line)) || ...
    any([ strncmp(ifit_options.line, {'file://','http://'},7) ...
          strncmp(ifit_options.line,  'ftp://', 6) ...
          strncmp(ifit_options.line,  'https://',8) ])
    ifit_options.line = textscan(ifit_options.line, '%s', 'Delimiter',' ');
    if ~isempty(ifit_options.line)  % filenames have been droped in the terminal
      ifit_options.line = ifit_options.line{1};
      this{end+1} = iData(ifit_options.line); % import them
      ifit_options.line = '';
      ans = this{end}
    end
  end
  
  % now do the work (evaluate what to do) --------------------------------------
  if ischar(ifit_options.line) && ~isempty(ifit_options.line), 
    try
      eval(ifit_options.line); 
    catch
      if length(ifit_options.line) > 250
        ifit_options.line = [ ifit_options.line(1:250) ' ...' ];
      end
      disp('Error when evaluating expression:')
      disp(ifit_options.line)
      disp(lasterr)
      ifit_options.line = '';
    end
  end
  
  % collect next command to execute: from input arguments, or prompt
  
  if exist('varargin') == 1 && ~isempty(varargin) % from command line ----------
    % we clear the argument from the command line after reading it
    ifit_options.line = varargin{1}; varargin(1) = []; 
    disp([ 'iFit:' num2str(ifit_options.index) '>> argument ' ifit_options.line ]);
    % specific case of imported arguments from the command line
    if (ifit_options.line(1)=='"' && ifit_options.line(end)=='"')
      % a "string" explicitly indicated as such
      ifit_options.line=ifit_options.line(2:(end-1));
      this{end+1} = ifit_options.line;
      ans = this{end};
      ifit_options.line = '';
    elseif (ifit_options.line(1)=='''' && ifit_options.line(end)=='''')
      % an 'expression' explicitly indicated as such
      ifit_options.line=ifit_options.line(2:(end-1));
      try
        ifit_options.line = eval(ifit_options.line);
      catch
        disp('Error when evaluating expression argument:')
        disp(ifit_options.line)
        disp(lasterr)
        ifit_options.line = '';
      end
      this{end+1} = ifit_options.line;
      ans = this{end};
      ifit_options.line = '';
    % some startup arguments known as commands
    elseif strcmp(ifit_options.line, '--save') || strcmp(ifit_options.line, '-s')
      ifit_options.save='ifit.mat'; ifit_options.line = '';
    elseif strncmp(ifit_options.line, '--save=', 7)
      ifit_options.save=ifit_options.line(8:end); ifit_options.line = '';
    elseif strncmp(ifit_options.line, '--run=', 6)
      ifit_options.line=[ 'run ' ifit_options.line(7:end) ];
    elseif strncmp(ifit_options.line, '-r=', 3)
      ifit_options.line=[ 'run ' ifit_options.line(4:end) ];
    elseif strcmp(ifit_options.line, '-r')
      ifit_options.line=varargin{1}; varargin(1) = []; 
    elseif strcmp(ifit_options.line, '--exit') || strcmp(ifit_options.line, '-e')
      ifit_options.line='exit';
    elseif strcmp(ifit_options.line, '--help') || strcmp(ifit_options.line, '-h')
      inline_display_usage; % see below
      ifit_options.line = '';
    elseif strncmp(fliplr(ifit_options.line), fliplr('.m'), 2)
      % a script is given as argument : execute it
      ifit_options.line=[ 'run ' ifit_options.line ];
    elseif ~isempty(str2num(ifit_options.line))
      % numerical value(ifit_options.line) as a matrix
      this{end+1} = str2num(ifit_options.line);
      ans = this{end}; % we do not print the output, which may be BIG
      ifit_options.line = '';
    elseif ismethod(iData, ifit_options.line) || ismethod(iFunc, ifit_options.line) ...
            || (any(exist(ifit_options.line) == [ 2 3 5 6 ]) && isempty(dir(ifit_options.line)))
      % a known method/function (iData, iFunc, ...) but not a file name
      try
        ans = nargout(ifit_options.line);
        if nargout(ifit_options.line) > 1, 
          ans=cell(1,nargout(ifit_options.line));
          [ans{:}]          = builtin('feval',ifit_options.line, this{:});
          ifit_options.line = ans;
        else
          ifit_options.line = builtin('feval',ifit_options.line, this{:});
        end
      catch
        disp('Error when evaluating method:')
        disp(ifit_options.line)
        if ~isempty(this), disp(this); end
        disp(lasterr)
      end
      this{end+1} = ifit_options.line;
      ans = this{end}
      ifit_options.line = '';
    elseif strncmp(fliplr(ifit_options.line), fliplr('.desktop'), 8) || strncmp(fliplr(ifit_options.line), fliplr('.bat'), 4)
      % a desktop launcher is given as argument : read operator/command
      % from it and evaluate
      ifit_options.line = launcher_read(ifit_options.line);
      try
        this{end+1} = eval(ifit_options.line); 
      catch
        this{end+1} = ifit_options.line;
      end
    else
      % argument is not an iFit/Matlab method, a command, a number, "string", 'expression', a script, a launcher
      % read data file and convert it to iData
      this{end+1} = iData(ifit_options.line);
      ifit_options.line = '';
      ans = this{end}
    end

    ifit_options.index=ifit_options.index+1;
    
    if isempty(varargin) && ~isempty(this) % last argument has just been processed
      disp('Info: all imported arguments have been stored in cell array ''this''.');
      disp('      access them with e.g. this{1} ... this{end}');
      disp('      to get all models:    this(cellfun(''isclass'',this,''iFunc''))')
      disp('      to get all data sets: this(cellfun(''isclass'',this,''iData'')).')
      disp('''this'' is:')
      disp(this);
      clear varargin
      % last file imported. Plot all imported data sets / functions
      if  isempty(ifit_options.line) % no command was given as last argument
        if 0 < length(this(cellfun('isclass',this,'iData'))) && length(this(cellfun('isclass',this,'iData'))) <= 20
          figure('Name','iFit: imported data sets'); 
          subplot(this{cellfun('isclass',this,'iData')});
        end
        if 0 < length(this(cellfun('isclass',this,'iFunc'))) && length(this(cellfun('isclass',this,'iFunc'))) <= 20
          figure('Name','iFit: imported models'); 
          subplot(this{cellfun('isclass',this,'iFunc')});
        end
      end
    end
  else % not from varargin, from prompt ----------------------------------------
    ifit_options.line = input([ 'iFit:' num2str(ifit_options.index) ' ' ],'s');
  end
  if ~isempty(strtrim(ifit_options.line))
    ifit_options.index=ifit_options.index+1;
  end
end

% auto save ?
if ischar(ifit_options.save)
  save(ifit_options.save, '-v7.3'); % default format is Matlab/HDF (compressed)
end

close all
disp([ '** Ending iFit on ' datestr(now) ])
disp(  '** Thanks for using iFit <ifit.mccode.org> **')

% ------------------------------------------------------------------------------
%                             inline private functions
% ------------------------------------------------------------------------------

function inline_display_banner
  disp(' ');
  % banner from http://www.network-science.de/ascii/
  disp('                             _  ______ _  __ ');
  disp('                            (_)/ ____/(_)/ /_  (C) ILL');
  disp('                           / // /_   / // __/ ');
  disp('                          / // __/  / // /_   ');
  disp('                         /_//_/    /_/ \__/   ');
  disp(' ');
  disp('                          ** Welcome to iFit **');
  disp('                            <ifit.mccode.org>');
  disp('                E. Farhi, Institut Laue Langevin, France (c)');
  disp('                      Licensed under the EUPL V.1.1');
  disp(' ');
  disp(version(iData));
  disp(' ');
  disp([ '** Starting iFit on ' datestr(now) ])
  disp('   Type ''help'' to learn how to use this software.');
  disp('   iFit   help is fully available at <http://ifit.mccode.org>.')
  disp('   Matlab help is fully available at <http://www.mathworks.com/help/techdoc>.')
  disp('   Type ''exit'' or Ctrl-C to exit.');
  if ispc
    disp('WARNING: Windows: file names containing spaces, such as "My Documents" ')
    disp('         are not well supported. Rename files or move directories.')
  end
  disp(' ')

function inline_display_help
  disp(version(iData, 'contrib'))
  disp([ 'Built using Matlab ' version ])
  disp(' ');
  disp('Enter any Matlab/iFit command.');
  disp('      Use ''run script.m'' to execute a script from a file.');
  disp('      Control statements are allowed (for/while loops, tests, ');
  disp('        switch/case...) when they span on one line, or in scripts.');
  disp('Keys: Arrow-Up/Down  Navigate in command history.');
  disp('      Ctrl-C         Exit (same as ''exit'' or ''return'' commands)');
  disp('Help: Type ''doc(iData,''iFit'')'' to open local web pages');
  disp('      or see <ifit.mccode.org> and contact <ifit-users@mccode.org>.');
  disp('      Type ''help <ifit topic/method>'' to display specific help.')
  disp('To import some data, use e.g. d=iData(''filename'');');
  disp('To create a model,   use e.g. m=iFunc(''expression''); ');
  disp('  or type fits(iFunc) to get a list of available models.');
  disp('To fit a model to data, use e.g. fits(m,d)');
  disp('Data and Models can be manipulated (+-/*...) using the Matlab syntax.');
  disp('Source code for this software is available at <ifit.mccode.org>.')
  disp('Matlab is a registered trademark of The Mathworks Inc.');
  disp('Matlab help is fully available at <http://www.mathworks.com/help/techdoc>.');
  
function inline_display_usage
  t = textwrap({ version(iData,'contrib') },80);
  fprintf(1, '%s\n', t{:});
  disp('Usage:  ifit [options] argruments commands ')
  disp(' ')
  disp('  iFit executable from command line.')
  disp('  Project page at <http://ifit.mccode.org>')
  disp(' ')
  disp('  arguments:')
  disp('    Any file name, including directories (imports all recursively).')
  disp('      Files can also be given as distant URLs (via http and ftp), and as compressed')
  disp('      content (zip, tar, gzip).')
  disp('      Script files (.m) are executed, other files are imported.')
  disp('    Any numerical value, including arrays given as e.g. ''[ 1 2 ...]''.')
  disp('    The ''empty'' argument is obtained from the ''[]'' argument')
  disp('    Any argument given between double quotes is used as a string argument.')
  disp('    Any argument given between simple quotes is evaluated as a an expression.')
  disp(' ')
  disp('  Once all arguments have been processed, they are stored in the ''this''')
  disp('    variable (cell array) for further use, and the program enters in interactive')
  disp('    mode except when the --exit argument is specified.')
  disp('  In interactive mode, any Matlab command can be entered.')
  disp(' ')
  disp('  options:')
  disp('  --exit or -e')
  disp('      exits immediately after all execution of command line arguments.')
  disp('  --save or -s or --save=FILE')
  disp('      saves all variables when commands have been executed.')
  disp('  --run=SCRIPT or -r=SCRIPT')
  disp('      executes the SCRIPT when starting.')
  disp(' ')
  disp('  Examples:')
  disp('    ifit --save file1.*  subplot ')
  exit; % exit the application
  
function line = inline_display_helpcommand(line)
  [t, line] = strtok(line); % remove first command 'help'
  line      = strtrim(line);
  if ~isempty(line), 
    disp([ 'web(' line ')' ]);
    web(line); 
    line = '';
  end  

function line = inline_runscript(line)
  line = strtrim(line(5:end)); % get script name
  if ~exist(line) && exist([ line '.m' ])
    line = [ line '.m' ];
  end
  if ~isempty(dir(line))
    [p,f,e]=fileparts(line);
    if isempty(p), p=pwd; end
    line = fullfile(p, [f e ]);
    disp([ 'Reading file ' line ]);
    line=fileread(line);
  else
    disp([ 'Error: iFit: Can not open script ' line ]);
  end
