function s = read_anytext(varargin)
% import any text using 'looktxt'.
%
% the importation consists in performing the following tasks:
% * handle arguments, looking for options (possibly with "string") and filenames
% * launch looktxt as MeX and MATfile format on temporary file
% * import the MAT file as a structure

% TODO: 
% support replacement by fread; regexprep; fprintf (NaN, Inf, ...)
% support option compile

% handle input arguments =======================================================
s = [];
if isempty(varargin)
  looktxt('--help');
  return
end

argv={};

user.outfile = '';
user.format  = '';
remove_tempname = 0;

% split the arguments, but retain those that contain "" and '' quotes
for index=1:length(varargin)
  arg = varargin{index};
  if ~ischar(arg)
    fprintf(1, 'read_anytext: argument is of class %s. Only char allowed. Ignoring\n', ...
      class(arg));
  else
    split = strread(arg,'%s','delimiter',' ;'); % split argument with common delimiters
    i_split = 1;
    while i_split <= length(split)
      this_split = split{i_split}; c='';
      if any(this_split == '''')  % is there an argument which contains a string ?
        c = '''';
      elseif any(this_split == '"')
        c = '"';
      end
      while ~isempty(c) && i_split < length(split)
        % assemble arguments until the last one that ends with the same delimiter
        i_split = i_split+1;
        this_split = [ this_split ' ' split{i_split} ];
        if any( split{i_split} == c )
          c = ''; % we have found the second string delimiter: end while loop
        end
      end
      if strncmp(this_split, '--outfile=', length('--outfile=')) ...
        user.outfile = length(argv)+1;
      elseif any(strcmp( this_split, {'-o','--outfile'})) % file name follows -o
        user.outfile = length(argv)+2;
      end
      if strncmp(this_split, '--format=', length('--format=')) ...
        user.format  = length(argv)+1;
      elseif any(strcmp( this_split, {'-f','--format'})) % format follows -f 
        user.format  = length(argv)+2;
      end
      argv{end+1} = this_split; % store this bit as an argument for looktxt
      i_split = i_split+1;
    end % for
  end
end

% launch looktxt with MATfile format and temporary file name ===================

% specify default output file name and format (if not defined by user)
if isnumeric(user.outfile) && user.outfile <= length(argv)
  user.outfile = argv{user.outfile}; 
end
if isnumeric(user.format) && user.format <= length(argv)
  user.format = argv{user.format}; 
end

% line below: we do not force MAT file write, and then request MEX
% with direct memory allocation in the Matlab workspace. faster by 15%.
if isempty(user.outfile) && 0
  user.outfile     = [ tempname '.mat' ];  % usually in TMP directory
  argv{end+1} = [ '--outfile=' user.outfile ];
  remove_tempname = 1;
elseif strncmp(user.outfile, '--outfile=', length('--outfile='))
  user.outfile= user.outfile((length('--outfile=')+1):end);
end
if strncmp(user.format, '--format=', length('--format='))
  user.format= user.format((length('--format=')+1):end);
  argv{end+1} = [ '--format=' user.format ];
elseif exist('looktxt') ~= 3 % use binary/executable, not MeX
  user.format= 'MATfile';
  argv{end+1} = [ '--format=' user.format ];
end

% call looktxt >>>>
if isempty(user.outfile)
  % pure MEX call. No temporary file.
  user.format= 'MEX';
  argv{end+1} = [ '--format=' user.format ];
  s = looktxt(argv{:});
else
  looktxt(argv{:});
  
  % import the MAT file from the temporary file, into structure ==================
  if ~isempty(user.outfile) && ischar(user.outfile) && ~isempty(dir(user.outfile))
    try
      s = load(user.outfile); % must be a MAT-file
      % check if there is only one struct field at first level then access it (probably
      % the temporary variable name).
      f = fieldnames(s);
      if length(f) == 1
        s = s.(f{1});
      end
    catch
      s = [];
    end
  end

  % delete temporary file ========================================================
  if remove_tempname && ~isempty(dir(user.outfile))
    delete(user.outfile);
  end
end

% convert the Headers field into Attributes
if isstruct(s)
  if isfield(s, 'Headers')
    s.Attributes = s.Headers;
    s=rmfield(s, 'Headers');
  end

  s=orderfields(s);

  if isfield(s, 'Data')
    s.Data = orderfields(s.Data);
  end  
end


