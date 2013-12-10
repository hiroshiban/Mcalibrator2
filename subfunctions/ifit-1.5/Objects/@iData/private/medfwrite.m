function filename=medfwrite(a, filename)
% private function to write EDF files

% tests on dimensionality
if ndims(a) > 2, 
  iData_private_warning(mfilename,[ 'Can only export 2D objects to EDF format. Object ' a.Tag ' has ndims=' num2str(ndims(a)) ]);
  filename=[]; 
  return; 
end

s = getaxis(a,0);
if ~numel(s), filename=[]; return; end

% create the header
header = pmedf_emptyHeader;

if     isa(s, 'int8'),  db=1; t='SignedByte';
elseif isa(s, 'uint8'), db=1; t='UnsignedByte';
elseif isa(s, 'int16'), db=2; t='Short';
elseif isa(s, 'uint16'),db=2; t='UnsignedShort';
elseif isa(s, 'int32'), db=4; t='SignedLong';
elseif isa(s, 'uint32'),db=4; t='UnsignedLong';
elseif isa(s, 'single'),db=4; t='FloatValue';
elseif isa(s, 'double'),db=8; t='DoubleValue';
else                    t='';
end
if isempty(t), filename=[]; return; end

header = pmedf_putInHeader(header, 'ByteOrder', 'LowByteFirst');
header = pmedf_putInHeader(header, 'DataType', t);
header = pmedf_putInHeader(header, 'EDF_DataBlockID', '1.Image.Signal');

[nr, nc] = size(s);
tmp = db*nr*nc; % data size
header = pmedf_putInHeader(header, 'Dim_1', sprintf('%i',nr));
header = pmedf_putInHeader(header, 'Dim_2', sprintf('%i',nc));
header = pmedf_putInHeader(header, 'Size',  sprintf('%i',tmp));
header = pmedf_putInHeader(header, 'Title', char(a));

% additional specific entries
header = pmedf_putInHeader(header, 'Tag', a.Tag);
header = pmedf_putInHeader(header, 'Source', a.Source);
if ~isempty(a.Label)
  header = pmedf_putInHeader(header, 'Label', a.Label);
end
if ~isempty(a.DisplayName)
  header = pmedf_putInHeader(header, 'DisplayName', a.Label);
end
header = pmedf_putInHeader(header, 'Creator', a.Creator);
header = pmedf_putInHeader(header, 'User', a.User);
header = pmedf_putInHeader(header, 'Date', get(a,'Date'));
header = pmedf_putInHeader(header, 'Modification', get(a,'ModificationDate'));

m = get(a,'Monitor'); 
if not(all(m==0| m==1))
  header = pmedf_putInHeader(header, 'SignalNormalizedToMonitor', 'Yes');
  title(a, [ title(a) ' per monitor' ]);
  m=mean(m(:));
  header = pmedf_putInHeader(header, 'Monitor', num2str(m));
end

e = get(a,'Error'); e=mean(e(:));
header = pmedf_putInHeader(header, 'Error', num2str(e));


if ndims(a) > 1,
  x = getaxis(a, 2);
  header = pmedf_putInHeader(header, 'Axis2_Label', xlabel(a));
  header = pmedf_putInHeader(header, 'Axis2_Min', min(x(:)));
  header = pmedf_putInHeader(header, 'Axis2_Max', max(x(:)));
  header = pmedf_putInHeader(header, 'Axis2_Length', length(unique(x(:))));
end
header = pmedf_putInHeader(header, 'Axis1_Label', ylabel(a));
y = getaxis(a, 1);
header = pmedf_putInHeader(header, 'Axis1_Min', min(y(:)));
header = pmedf_putInHeader(header, 'Axis1_Max', max(y(:)));
header = pmedf_putInHeader(header, 'Axis1_Length', length(unique(y(:))));

header = pmedf_putInHeader(header, 'EDF_HeaderSize', '1024');
if ~isempty(title(a))
  header = pmedf_putInHeader(header, 'Signal_Label', title(a));
end

% calls the pmedf_write function
header = pmedf_write ( filename, header, s );
if isempty(header), filename=''; end % an error was met

% ------------------------------------------------------------------------------

%% Writing ESRF header files: .edf files.
%% Writes the header and the matrix with the data. 
%%
%% Usage:  
%%	new_header = pmedf_write ( filename, header, data )
%%
%% Filename should have '.edf', '.edf.gz' or '.edf.bz2' extension.
%%
%% It returns the header of the file written.
%%
%% Data are stored under the short/double/integer format according to
%% the specification in the header.
%%
%% Date key in the header unchanged (yet): Octave is OK, but Matlab does not 
%% provide  "ctime(time());"
%%
%% Example: 
%%	[bone.h, bone.a] = pmedf_read('bone0007.edf');
%%	new_header = pmedf_write('bone0007_new.edf', bone.h, bone.a);
%%
%% Author: Petr Mikulik
%% Version: 31. 5. 2010
%% History:
%%	May 2010: Report an error under Matlab if writing .gz/.bz2 data.
%%	June 2006: Support for writing signed datatyped.
%%	February 2005: Added writing .gz and .bz2 files.
%%	May 2002: rewrite for string-like header of edf files.
%%	13. 4. 2000: version for ehf files (structure of header fields).

function new_header = pmedf_write ( edffile, header, data )

new_header = [];

if nargin ~= 3
  fprintf('Usage: pmedf_write ( filename, header, data )\n');
  return
end

edf.datatype = pmedf_findInHeader(header, 'DataType', 'string');
edf.byteorder = pmedf_findInHeader(header, 'ByteOrder', 'string');
edf.dim1 = pmedf_findInHeader(header, 'Dim_1', 'int');
edf.dim2 = pmedf_findInHeader(header, 'Dim_2', 'int');
edf.size = pmedf_findInHeader(header, 'Size', 'int');

[nr, nc] = size(data);
if edf.dim1~=nr
    header = pmedf_putInHeader(header, 'Dim_1', sprintf('%i',nr));
    edf.dim1 = nr;
end
if edf.dim2~=nc
    header = pmedf_putInHeader(header, 'Dim_2', sprintf('%i',nc));
    edf.dim2 = nc;
end
switch edf.datatype
    case {'UnsignedInteger', 'UnsignedLong'}, dt='uint32'; db=4;
    case 'UnsignedShort', dt='uint16'; db=2;
    case 'UnsignedByte', dt='uint8'; db=1;
    case {'SignedInteger', 'SignedLong', 'Integer'}, dt='int32'; db=4;
    case {'SignedShort', 'Short'}, dt='int16'; db=2;
    case 'SignedByte', dt='int8'; db=1;
    case {'Float', 'FloatValue'}, dt='single'; db=4;
    case {'Double', 'DoubleValue'}, dt='double'; db=8;
    otherwise error(['Unknown data type "', edf.datatype, '" of file "', f, '"']);
end
tmp = db*nr*nc; % data size
if edf.size~=tmp
    header = pmedf_putInHeader(header, 'Size', sprintf('%i',tmp));
    edf.size = tmp;
end
switch edf.byteorder
    case 'HighByteFirst', arch='ieee-be';
    case 'LowByteFirst',  arch='ieee-le';
    otherwise arch='native';
end

% open the output file
l = length(edffile);
if l >= 3 & strcmp(edffile(l-2:end),'.gz')	% write .edf.gz
    if exist('OCTAVE_VERSION', 'builtin')~=5
	error('pmedf message: gzipped data cannot be written under Matlab without a temporary file; please use Octave instead.');
    end
    is_pipe = 1;
    fid = popen(['gzip >', edffile],'w');
elseif l >= 4 & strcmp(edffile(l-3:end),'.bz2') % write .edf.bz2
    if exist('OCTAVE_VERSION', 'builtin')~=5
	error('pmedf message: bzipped data cannot be written under Matlab without a temporary file; please use Octave instead.');
    end
    is_pipe = 1;
    fid = popen(['bzip2 >', edffile],'w');
else
    is_pipe = 0;
    [fid, msg] = fopen(edffile,'wb');
end
if fid == -1
  fprintf('pmedf_write: cannot write file "%s"\n', edffile);
  return
end

if fid==-1
    fprintf('pmedf_write: cannot write file "%s"\n', edffile);
else
    fprintf('Writing %i x %i x %s to file "%s"\n',edf.dim1,edf.dim2,edf.datatype,edffile);
%    if (ehf.offset ~= 0)
%	fprintf('SKIPPING offset is not yet supported! But it is easy...\n');
%    end
    % Write header:
    fprintf(fid, '%s', header);
    % Write data:
    count = fwrite(fid, data, dt, 0, arch);
%   count = fwrite(fid, data', s, 0, arch);
    if count~=nr*nc
	fprintf('ERROR writing file %s (disk full?)\n', edffile);
    end
    if is_pipe
	pclose(fid);
    else
	fclose(fid);
    end
end

new_header = header;

% eof pmedf_write.m

% ------------------------------------------------------------------------------

%% pmedf_findInHeader --- find value of a given key in edf file header
%%
%% Usage:
%%	value = pmedf_findInHeader( header, key [, typ] )
%%
%% In the 'header' (a string, usually a multiple of 512 B as the ESRF edf file
%% header), find keyword 'key' and return its 'value' converted to type 'typ',
%% which can be 'string' (default), 'int' or 'float'.
%%
%% Returns [] if the keyword has not been found.
%%
%% Tech note: regular expression for a header line is
%%	\nkey [ ]*= [ ]*value[ ]*;\n
%%
%% Examples:
%%	pmedf_findInHeader( header, 'Dim_1', 'int' );
%%	pmedf_findInHeader( header, 'Title', 'string' );
%%	pmedf_findInHeader( header, 'Title' );
%%	pmedf_findInHeader( header, 'PSize_1', 'float' );
%%
%% Author: Petr Mikulik
%% Version: 29. 10. 2008
%% History: October 2008: Catch file header written with CRLF.
%%			  Fix for always short-circuited |.
%%	    September 2004: Use isempty() where necessary.
%%	    May 2002: First version.

function value = pmedf_findInHeader( header, key, typ )

if nargin<2 | nargin>3
    error('syntax: pmedf_findInHeader(...)');
end

key = sprintf(['\n' key ' ']);
% without sprintf there would be 2 characters instead of one "\n" in Matlab
value = findstr(header, key);
if isempty(value) return; end

header = header(value(1):length(header));
p = findstr(header, sprintf(';\n'));
if  isempty(p) % file header written with CRLF
    p = findstr(header, sprintf(';\r\n'));
end

header = header(1:p(1)-1);
p = findstr(header, '= ');
header = header(p(1)+2:length(header));
% trim trailing spaces
value = deblank(header);
% trim leading spaces
p = findstr(value, ' ');
if ~isempty(p)
    % Octave OK, Matlab fails: p = find(p - [1:length(p)] > 0)(1);
    p = find(p - [1:length(p)] > 0);
    value = value(p(1):length(value));
end

% Return value according to 'typ':
if nargin==2 return; end
if strcmp(typ,'string') return; end
if strcmp(typ,'int') [value, tmp] = sscanf(value, '%i', 1); return; end
if strcmp(typ,'float') [value, tmp] = sscanf(value, '%g', 1); return; end
error('unknown "typ"');

% eof pmedf_findInHeader.m

% ------------------------------------------------------------------------------

%% Returns an empty header (1x1x1 B).
%%
%% Syntax:
%%	pmedf_emptyHeader ( [headersize] );
%% where
%%	headersize: an optional parameter (default 1024) extends the header
%%	size to this value; note this it has to be a multiple of 512.
%%	Note: special case were headersize==0 can be used for writing EHF
%%	files (separate header and binary data file); then, no padding is
%%	performed. Use with caution.
%%
%%
%% Author: Petr Mikulik
%% Version: May 2002

function header = pmedf_emptyHeader ( headersize )

if nargin > 1
    error('usage: pmedf_emptyHeader( [headersize] )');
end

if nargin==0
    headersize = 1024;
end

header = sprintf('{\nHeaderID = EH:000001:000000:000000 ;\nImage = 1 ;\nByteOrder = LowByteFirst ;\nDataType = UnsignedByte ;\nDim_1 = 1 ;\nDim_2 = 1 ;\nSize = 1 ;\n');
% sprintf('\n') due to Matlab incompatibility

if headersize==0
    header = [header sprintf('}\n')];
else
    if mod(headersize, 512)~=0
	headersize = 512*ceil(headersize/512);
    end
    if length(header)+2 > headersize
	headersize = 512*ceil((length(header)+2)/512);
    end
    header = [header repmat(' ', 1, headersize-length(header)-2) sprintf('}\n')];
end

% eof pmedf_emptyHeader.m

% ------------------------------------------------------------------------------

%% pmedf_putInHeader --- puts the given key and its value in edf file header:
%% a new entry is added at the end, an existing key is updated.
%%
%% Usage:
%%	header = pmedf_putInHeader( header, key, new_value [, pos] )
%%
%% In the 'header' (a string, usually a multiple of 512 B as the ESRF edf file
%% header), find keyword 'key'; if it exists, then replace its value by
%% 'new_value', otherwise add a new line. Keep the original size of the
%% header if possible, otherwise extend it by multiples of 512 B.
%% The "=" separating the key and its value is copied from the existing
%% position if the key exists, otherwise positioned at the given 'pos'
%% or separated from the key by a single space.
%%
%% Tech note: regular expression for a header line is
%%	\nkey [ ]*= [ ]*value[ ]*;\n
%%
%% Examples:
%%	header = pmedf_putInHeader( header, 'energy', 12.3 );
%%	header = pmedf_putInHeader( header, 'note', 'after alignment' );
%%	header = pmedf_putInHeader( header, 'note', 'after alignment', 16 );
%%
%% Author: Petr Mikulik
%% Version: 31. 5. 2010
%% History: May 2010: Replace rindex() by findstr(end).
%%	    September 2004: Use isempty() where necessary.
%%	    May 2002: First version.

function header = pmedf_putInHeader( header, key, new_value, pos )

if nargin<3 | nargin>4
    error('syntax: pmedf_putInHeader(...)');
end

key = [sprintf('\n') key ' '];
    % bloody Matlab \n incompatibility
if isnumeric(new_value) new_value = sprintf('%g', new_value); end
value = findstr(header, key);
orig_size = length(header);

if ~isempty(value) % the key already exists
    header_beg = [header(1:value(1)-1)];
    header = header(value(1):length(header));
    p = findstr(header, sprintf(';\n'));
    line = header(1:p(1)-1);
    header = header(p(1)+2:length(header)-2); % don't copy the trailing '}\n'
    p = findstr(line, '= ');
    line = line(1:p(1)+1);
    header = [header_beg line new_value sprintf(' ;\n') header];
    % strip the trailing spaces after the last line
    p = findstr(header, sprintf(';\n'));
    header = header(1:p(end)+1);
else % the key does not exist yet
    p = findstr(header, sprintf(';\n'));
    header = header(1:p(end));
    if nargin==3 
	pos = 0;
    end
    pos = pos - length(key) - 1; % how many spaces to add
    if pos > 1
	spaces = [repmat(' ', 1, pos+1)];
	header = [header key spaces '= ' new_value sprintf(' ;\n')];
    else
	header = [header key '= ' new_value sprintf(' ;\n')];
    end
end

% now extend the header to its original size or extend it
l = length(header);
if l+2 > orig_size % extend the header
    orig_size = 512*ceil(l/512);
end
header = [header repmat(' ', 1, orig_size-l-2) sprintf('}\n')];

% eof pmedf_putInHeader.m
