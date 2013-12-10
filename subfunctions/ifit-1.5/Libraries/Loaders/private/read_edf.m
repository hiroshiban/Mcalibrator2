function s = read_edf(filename)
% medfread Wrapper to pmedf_read which reconstructs the EDF structure
% only reads the first block/image

s = [];
% read the file
[header, data] = pmedf_read(filename);
if isempty(header), return; end

% split the header lines
header = strread(header,'%s','delimiter',sprintf('\n'));

for index=1:length(header)
  this_line=strread(header{index},'%s','delimiter','=');
  if length(this_line) == 2
    % check if value is numeric
    if ~isempty(str2num(this_line{2}))
      this_line{2} = str2num(this_line{2});
    end
    s = setfield(s, strtrim(this_line{1}), this_line{2});
  end
end

s.Signal = data;

%% Reading ESRF header files: .ehf / .edf files.
%%
%% Usage:
%%	[header, data] = pmedf_read('hello.edf');
%%	header = pmedf_read('hello.edf');
%%
%% The first syntax reads both the header and the data; the second one reads
%% only the header, which can be useful for parsing header information.
%%
%% Author: Petr Mikulik
%% Version: 31. 5. 2010
%% History:
%%	    May 2010:
%%		Report an error under Matlab if reading .gz/.bz2 data.
%%	    May 2008:
%%		Minor clean-up.
%%	    June 2006:
%%		Use the C++ plugin pmedf_readC if it exists; it is several
%%		times faster. (Currently (Octave up to 2.1.72) has slow fread()
%%		function for skip=0.)
%%	    February 2005:
%%		Don't read the data if only the header output argument requested.
%%		Better protection against files with a broken header.
%%		Added reading .gz and .bz2 files.
%%		Reread file if data not fully read (was happening with pipe).
%%	    September 2004:
%%		if (0) and warning for fscanf('%c') by Octave >=2.1.55.
%%	    May 2002:
%%		Rewrite into a new routine pmedf_read(); this one does not
%%		return a structure of keywords, but the whole header. This may
%%		be redefined, later?
%%	    2001:
%%		pmehf_read updated to read ID19 EDF files.
%%	    April 2000:
%%		pmehf_read.m for EHF files at ID1.

% Copyright (C) 2010 Petr Mikulik
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details. 
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
% USA.

function [header, data] = pmedf_read ( f )

if nargin ~= 1
    fprintf('Usage:\n');
    fprintf('  [header {, image}] = pmedf_read.m(edf_filename)\n');
    return
end

% if the fast C++ plugin exists, then use it
if exist('pmedf_readC', 'file')
    if nargout == 1
	header = pmedf_readC(f);
    else
	[header, data] = pmedf_readC(f);
    end
    return
end

% open the file
l = length(f);
if l >= 3 & strcmp(f(l-2:end),'.gz')	  % read .edf.gz
    if exist('OCTAVE_VERSION', 'builtin')~=5
	error('pmedf message: gzipped data cannot be read under Matlab without a temporary file; please use Octave instead.');
    end
    is_pipe = 1;
    popen_cmd = ['gzip -d -c ', f];
    fid = popen(popen_cmd,'r');
elseif l >= 4 & strcmp(f(l-3:end),'.bz2') % read .edf.bz2
    if exist('OCTAVE_VERSION', 'builtin')~=5
	error('pmedf message: bzipped data cannot be read under Matlab without a temporary file; please use Octave instead.');
    end
    is_pipe = 1;
    open_cmd = ['bzip2 -d -c ', f];
    fid = popen(popen_cmd, 'r');
else
    is_pipe = 0;
    [fid, msg] = fopen(f,'rb');
end
if fid == -1,
    fprintf('pmedf_read: cannot open file "%s"\n',f);
    return
end

% read the header
hsize = 512; % edf header size is a multiple of 512
closing = sprintf('}\n');
% The stupid construct above due to Matlab non-interpretation of escape
% sequences in string; Octave (like C and C++) is OK with
% closing = '}\n';
if 0 % Octave 2.1.55 produces warning of "implicit conversion from matrix to string"
    [header, count] = fscanf(fid,'%c',512);
else
    [tmp, count] = fread(fid, 512, 'char');
    header = sprintf('%c', tmp);
end
% check if this an EDF file
if isempty(strfind(header,'DataType')) || isempty(strfind(header,'ByteOrder')) ...
|| isempty(strfind(header, 'Size')) || isempty(strfind(header, 'Dim_1'))
  error([ mfilename ': ' f ' is probably not an EDF file.' ])
end

while ~strcmp(header(length(header)-length(closing)+1:length(header)), closing)
    if 0 % Octave 2.1.55 produces warning of "implicit conversion from matrix to string"
    	header = [header, fscanf(fid, '%c', hsize)];
    else
	[tmp, count] = fread(fid, 512, 'char');
    	header = [header, sprintf('%c', tmp)];
	if count<512 % this is not an edf file
	    header = [];
	    data = [];
	    return; 
	end
    end
end

if nargout == 1
    % One output argument requested => return immediately with just the header.
    if is_pipe
	pclose(fid);
    else
	fclose(fid);
    end
    return
end

edf.datatype = pmedf_findInHeader(header, 'DataType', 'string');
edf.byteorder = pmedf_findInHeader(header, 'ByteOrder', 'string');
edf.dim1 = pmedf_findInHeader(header, 'Dim_1', 'int');
edf.dim2 = pmedf_findInHeader(header, 'Dim_2', 'int');
edf.size = pmedf_findInHeader(header, 'Size', 'int');

% Note - summary of ID1 ehf keywords:
% EDF_BinaryFileName EDF_BinaryFilePosition DataType ByteOrder Dim_1 Dim_2
% PSize_1 PSize_2 DetectorPosition Title Center_1 Center_2 Wavelength
% ESRF_ID01_Goniometer_Theta ESRF_ID01_Goniometer_Chi ESRF_ID01_Goniometer_Phi
% ExposureTime HS32Z02==Monitor
% Note - my own keywords: scale_x scale_y, e.g. for reciprocal space scaling

% Read the binary file
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

% Checking -- what is more reliable?
% There must be  edf.dim1*edf.dim2*db == edf.size

% Note: reading EHF files requires to close the current file and 
% open that given by the 'EDF_BinaryFileName'. Not implemented yet.

% if (length(edf.filename) > 0)
%	fclose(fid);
%       [fid,msg] = fopen(edf.filename,'rb');
%	f = edf.filename;
%      else
%      	% stay at the current position
%        [fid,msg] = fopen(f,'rb');
%	fseek(fid, curr_pos, SEEK_SET);
%      end
%      if fid==-1
%   	fprintf('Cannot open image file "%s"\n',f);
%    	data=0;
%      end
% end % etc...

% Reading single edf file (contains the header and immediately following 
% binary data):

% Note: dim1 == sizex, dim2 == sizey

fprintf('Reading %i x %i x %s from file \"%s\"\n',edf.dim1,edf.dim2,dt,f);

switch edf.byteorder
    case 'HighByteFirst', arch='ieee-be';
    case 'LowByteFirst',  arch='ieee-le';
    otherwise arch='native';
end

% if (edf.offset ~= 0)
%    fprintf('SKIPPING offset is not yet supported!\n');
% end
[data, count] = fread(fid, [edf.dim1,edf.dim2], dt, 0, arch);
if edf.dim1*edf.dim2 ~= count
    % Ooops, a trouble -- data were not completely read. This was sometimes
    % happening when reading many files via pipe.
    % Let's try to reopen and reread the file.
    fprintf('  --> ooops, problem reading last %i B out of %i B, retrying...\n', edf.dim1*edf.dim2-count, edf.dim1*edf.dim2);
    if is_pipe
	pclose(fid);
	pause(1); % pause 1 second
	fid = popen(popen_cmd,'r');
    else
	fclose(fid);
	pause(1); % pause 1 second
	[fid, msg] = fopen(f,'rb');
    end
    if fid == -1,
	fprintf('    --> pmedf_read: cannot reopen file "%s"\n',f);
	return
    end
    % skip the header
    [data, count] = fread(fid, length(header), 'uchar', 0, arch);
    if count~=length(header)
	fprintf('    --> pmedf_read: cannot reread header from file "%s"\n',f);
	return
    end
    % read the data again
    [data, count] = fread(fid, [edf.dim1,edf.dim2], dt, 0, arch);
    if edf.dim1*edf.dim2 ~= count
	fprintf('    --> pmedf_read: cannot reread data from file "%s"\n',f);
	return
    end
end

% data flipping conversion:
% if using
%   data = data';
% then imagesc(data) makes the same image as ImageJ and onze.
% If the transpose is not done here, then you must do it yourself.
% Note: ID19 matlab macros do NOT transpose the image to onze compatibility.

if is_pipe
    pclose(fid);
else
    fclose(fid);
end

% eof pmedf_read.m

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


