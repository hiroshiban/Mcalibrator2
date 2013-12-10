%
% Filename: $RCSfile: cbfread.m,v $
%
% Revision: 1.1   Date: 2008/06/10 17:05:13 
% Author: bunk 
% Tag: 
%
% Description:
% Macro for reading Crystallographic Binary File (CBF) files written by the
% Pilatus detector control program camserver. 
%
% Note:
% Compile the C-program cbf_uncompress using mex (see header of
% cbf_uncompress.c) to use it for uncompression instead of the slower
% Matlab code. 
% Currently this routine supports only the subset of CBF features needed to
% read the Pilatus detector data. 
% Call without arguments for a brief help text.
%
% Dependencies:
% - image_read_set_default
% - fopen_until_exists
% - get_hdr_val
% - compiling cbf_uncompress.c increases speed but is not mandatory
%
%
% history:
%
% May 9th 2008, Oliver Bunk: 1st version
%

% example CBF at files at <http://www.bernstein-plus-sons.com/software/CBF/>
% original Matlab source code from SLS/cSAXS <http://www.psi.ch/sls/csaxs/software>

function [frame,vararg_remain] = read_cbf(filename,varargin)

% 0: no debug information
% 1: some feedback
% 2: a lot of information
debug_level = 0;

% initialize return argument
frame = struct('header',[], 'data',[]);


% check minimum number of input arguments
if (nargin < 1)
    error('At least the filename has to be specified as input parameter.');
end

% accept cell array with name/value pairs as well
no_of_in_arg = nargin;
if (nargin == 2)
    if (isempty(varargin))
        % ignore empty cell array
        no_of_in_arg = no_of_in_arg -1;
    else
        if (iscell(varargin{1}))
            % use a filled one given as first and only variable parameter
            varargin = varargin{1};
            no_of_in_arg = 1 + length(varargin);
        end
    end
end

% check number of input arguments
if (rem(no_of_in_arg,2) ~= 1)
    error('The optional parameters have to be specified as ''name'',value pairs');
end
    
% set default values for the variable input arguments and parse the named
% parameters: 
vararg = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        otherwise
            % pass further arguments on to fopen_until_exists
            vararg{end+1} = name;
            vararg{end+1} = value;
    end
end


% expected maximum length for the text header
max_header_length = 2*4096;

% end of header signature
eoh_signature = char([ 12 26 4 213 ]);

% CBF file signature
cbf_signature = '###CBF: VERSION';

% Calling an external C routine for uncompressing the data did save about
% 30% time on a specific machine. 
% The C-routine is used if a compiled version of it exists. 
% See the header of cbf_uncompress.c for information on how to compile the
% C file using mex in Matlab. 
c_routine = (length(which('cbf_uncompress')) > 0);
if ~c_routine
  mexfile = which('cbf_uncompress.c');
  mexpath = fileparts(mexfile);
  exec = [ 'mex -O -output ' mexpath filesep 'cbf_uncompress ' mexfile ];
  disp(exec);
  try
    eval(exec);
  catch
    if ispc
      % assume we use LCC
      exec=['mex -O -v -output ' mexpath filesep 'cbf_uncompress ' mexfile ' -L"' fullfile(matlabroot,'sys','lcc','lib') '" -lcrtdll' ];
      disp(exec);
      eval(exec);
    else
      warning([ mfilename ': MeX compilation failed. Using the pure Matlab version.' ]);
    end
  end
  rehash
end
if strcmp(filename, 'compile'), return; end

% try to open the data file
if (debug_level >= 1)
    fprintf('Opening %s.\n',filename);
end
[fid,vararg_remain] = fopen_until_exists(filename,vararg);
if (fid < 0)
    return;
end

% read all data at once
[fdat,fcount] = fread(fid,'uint8=>uint8');

% close input data file
fclose(fid);
if (debug_level >= 2)
    fprintf('%d data bytes read\n',fcount);
end

% search for end of header signature within the expected maximum length of
% a header
end_of_header_pos = ...
    strfind( fdat(1:min(max_header_length,length(fdat)))',...
             eoh_signature );
  
if (length(end_of_header_pos) < 1)
    cbf_error(filename,'no header end signature found');
    return;
end
if (debug_level >= 2)
    fprintf('Header length is %d bytes.\n',end_of_header_pos -1);
end

% return the complete header as lines of a cell array
frame.header = char_to_cellstr( char(fdat(1:(end_of_header_pos-1))') );

% check for CBF signature
if (~strncmp(cbf_signature,frame.header{1},length(cbf_signature)))
    cbf_error(filename,[ 'CBF signature ''' cbf_signature ...
        ''' not found in first line ''' frame.header{1} '''' ]);
end

% extract the mandatory information for decompression from the header
no_of_bin_bytes = get_hdr_val(frame.header,'X-Binary-Size:','%f',1);
dim1 = get_hdr_val(frame.header,'X-Binary-Size-Fastest-Dimension:','%f',1);
dim2 = get_hdr_val(frame.header,'X-Binary-Size-Second-Dimension:','%f',1);
el_type = get_hdr_val(frame.header,'X-Binary-Element-Type: "','%[^"]',1);
switch (el_type)
    case 'signed 32-bit integer'
        bytes_per_pixel = 4;
    otherwise
        cbf_error(filename,[ 'unknown element type ' el_type ]);
end
compr_type = get_hdr_val(frame.header,'conversions="','%[^"]',1);
switch (compr_type)
    case 'x-CBF_BYTE_OFFSET' 
        compression_type = 1;
    case 'x-CBF_NONE'
        compression_type = 2;
    otherwise
        cbf_error(filename,[ 'unknown compression type ' compr_type ]);
end
if (debug_level >= 2)
    fprintf('Frame dimensions are %d x %d.\n',dim2,dim1);
end

% uncompress the binary data
[frame.data] = ...
    extract_frame(fdat((end_of_header_pos+length(eoh_signature)):end),...
        dim1,dim2,no_of_bin_bytes,compression_type,...
        filename,...
        c_routine,debug_level);
    

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = cbf_error(filename,text)

fprintf('cbfread of %s:\n %s\n',filename,text);
return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [frame] = ...
    extract_frame(dat_in,...
        dim1,dim2,no_of_in_bytes,compression_type,...
        filename,...
        c_routine,debug_level)

% uncompressed data are copied directly
if (compression_type == 2)
    % initialize return array
    frame = zeros(dim1,dim2);
    % copy uncompressed data
    for (ind_out = 1:(dim1*dim2))
        ind_in = ind_out *4 -3;
        frame(ind_out) = double(dat_in(ind_in)) + ...
            256 * double(dat_in(ind_in+1)) + ...
            65536 * double(dat_in(ind_in+2)) + ...
            16777216 * double(dat_in(ind_in+3));
    end
    return;
end


if (c_routine)    
    if (debug_level >= 2)
        fprintf('C routine called.\n');
    end
    [frame] = ...
        cbf_uncompress(dat_in,dim1,dim2,no_of_in_bytes,compression_type);
    return;
end

if (debug_level >= 2)
    fprintf('Matlab routine called.\n');
end


% initialize return array
frame = zeros(dim1,dim2);

% only byte-offset compression is supported
if (compression_type ~= 1)
    cbf_error(filename,...
        ['extract_frame does not support compression type no. ' ...
        num2str(compression_type)]);
end


% In byte-offset compression the difference to the previous pixel value is
% stored as a byte, 16-bit integer or 32-bit integer, depending on its
% size. 
% The sizes above one byte are indicated by the escape sequence -1 in the
% previous data format, i.e, a 32-bit integer is preceded by the sequence %
% 0x80 (too large for a byte)
% 0x8000 (too large for a 16-bit integer). 
ind_out = 1;
ind_in = 1;
val_curr = 0;
val_diff = 0;
while (ind_in <= no_of_in_bytes)
    val_diff = double(dat_in(ind_in));
    ind_in = ind_in +1;
    if (val_diff ~= 128)
        % if not escaped as -128 (0x80=128) use the current byte as
        % difference, with manual complement to emulate the sign
        if (val_diff >= 128)
            val_diff = val_diff - 256;
        end
    else
        % otherwise check for 16-bit integer value
        if ((dat_in(ind_in) ~= 0) || (dat_in(ind_in+1) ~= 128))
            % if not escaped as -32768 (0x8000) use the current 16-bit integer
            % as difference 
            val_diff = double(dat_in(ind_in)) + ...
                256 * double(dat_in(ind_in+1));
            % manual complement to emulate the sign
            if (val_diff >= 32768)
                val_diff = val_diff - 65536;
            end
            ind_in = ind_in +2;
        else
            ind_in = ind_in +2;
            % if everything else failed use the current 32-bit value as
            % difference
            val_diff = double(dat_in(ind_in)) + ...
                256 * double(dat_in(ind_in+1)) + ...
                65536 * double(dat_in(ind_in+2)) + ...
                16777216 * double(dat_in(ind_in+3));
            % manual complement to emulate the sign
            if (val_diff >= 2147483648)
                val_diff = val_diff - 4294967296;
            end
            ind_in = ind_in +4;
        end
    end
	val_curr = val_curr + val_diff;
    frame(ind_out) = val_curr;
    ind_out = ind_out +1;
end
    
if (ind_out-1 ~= dim1*dim2)
    cbf_error(filename,[ 'mismatch between ' num2str(ind_out-1) ...
        ' bytes after decompression with ' num2str(dim1*dim2) ...
        ' expected ones' ]);
end


% if (~original_orientation)
%     frame.data = frame.data(end:-1:1,end:-1:1)';
% end


% ------------------------------------------------------------------------------

%
% Filename: $RCSfile: cbfread.m,v $
%
% $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
% $Author: farhi $
% $Tag: $
%
% Description:
% Convert an array of text to a cell array of lines.
%
% Note:
% Used for making file headers accessible. 
%
% Dependencies:
% none
%
%
% history:
%
% June 22nd 2008, Oliver Bunk: bug fix for fliread adding the nl_only 
% parameter, to be replaced by named parameter later on
%
% May 9th 2008, Oliver Bunk: 1st version
%
function [outstr] = char_to_cellstr(inchars,nl_only)

if (nargin < 2)
    nl_only = 0;
end

% get positions of end-of-line signatures
eol_ind = regexp(inchars,'\r\n');
eol_offs = 1;
if ((length(eol_ind) < 1) || (nl_only))
    eol_ind = regexp(inchars,'\n');
    eol_offs = 0;
end
if (length(eol_ind) < 1)
    eol_ind = length(inchars) +1;
end
if (length(eol_ind) < 1)
    outstr = [];
    return;
end

% dimension return array with number of lines
outstr = cell(length(eol_ind),1);

% copy the lines to the return array, suppressing empty lines
start_pos = 1;
ind_out = 1;
for (ind = 1:length(eol_ind))
    end_pos = eol_ind(ind) -1;
    % cut off trailing spaces
    while ((end_pos >= start_pos) && (inchars(end_pos) == ' '))
        end_pos = end_pos -1;
    end
    % store non-empty strings
    if (end_pos >= start_pos)
        outstr{ind_out} = inchars(start_pos:end_pos);
        ind_out = ind_out +1;
    end
    
    start_pos = eol_ind(ind) +1 + eol_offs;
    ind = ind +1;
end

% resize cell array in case of empty lines
if (ind_out <= length(eol_ind))
    outstr = outstr(1:(ind_out-1));
end


% ------------------------------------------------------------------------------

%
% Filename: $RCSfile: cbfread.m,v $
%
% $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
% $Author: farhi $
% $Tag: $
%
% Description:
% Open a file, in case of failure retry repeatedly if this has been
% specified. 
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies:
% none
%
%
% history:
%
% September 5th 2009, Oliver Bunk:
% bug fix in the zero file length check
%
% August 28th 2008, Oliver Bunk: 
% use dir rather than fopen to check for the file and check additionally
% that it is not of length zero
%
% May 9th 2008, Oliver Bunk: 1st version
%
function [fid,vararg_remain] = fopen_until_exists(filename,varargin)

% set default values for the variable input arguments and parse the named
% parameters:

% If the file has not been found and if this value is greater than 0.0 than
% sleep for the specified time in seconds and retry reading the file. 
% This is repeated until the file has been successfully read
% (retry_read_max=0) or until the maximum number of iterations is exceeded
% (retry_read_max>0). 
retry_read_sleep_sec = 0.0;
retry_read_max = 0;
retry_sleep_when_found_sec = 0.0;

% exit with error message if the file has not been found
error_if_not_found = 1;

% display a message once in case opening failed
message_if_not_found = 1;

if (nargin < 1)
    fprintf('Usage:\n');
    fprintf('[fid] = %s(filename [[,<name>,<value>],...]);\n',...
        mfilename);
    fprintf('filename                             name of the file to open\n');
    fprintf('The optional name value pairs are:\n');
    fprintf('''RetryReadSleep'',<seconds>           if greater than zero retry opening after this time (default: 0.0)\n');
    fprintf('''RetryReadMax'',<0-...>               maximum no. of retries, 0 for infinity (default: 0)\n');
    fprintf('''RetrySleepWhenFound'',<seconds>      if greater than zero wait for this time after a retry succeeded (default: %.1f)\n', ...
        retry_sleep_when_found_sec);
    fprintf('''MessageIfNotFound'',<0-no,1-yes>     display a mesage if not found, 1-yes is default\n');
    fprintf('''ErrorIfNotFound'',<0-no,1-yes>       exit with an error if not found, default is 1-yes\n');
    fprintf('The file ID of the opened file is returned or -1 in case of failure.\n');
    error('Invalid number of input parameters.');
end

% check minimum number of input arguments
if (nargin < 1)
    display_help();
    error('At least the filename has to be specified as input parameter.');
end

% accept cell array with name/value pairs as well
no_of_in_arg = nargin;
if (nargin == 2)
    if (isempty(varargin))
        % ignore empty cell array
        no_of_in_arg = no_of_in_arg -1;
    else
        if (iscell(varargin{1}))
            % use a filled one given as first and only variable parameter
            varargin = varargin{1};
            no_of_in_arg = 1 + length(varargin);
        end
    end
end
% check number of input arguments
if (rem(no_of_in_arg,2) ~= 1)
    error('The optional parameters have to be specified as ''name'',''value'' pairs');
end


% parse the variable input arguments
vararg_remain = cell(0,0);
for ind = 1:2:length(varargin)
    name = varargin{ind};
    value = varargin{ind+1};
    switch name
        case 'RetryReadSleep'
            retry_read_sleep_sec = value;
        case 'RetryReadMax'
            retry_read_max = value;
        case 'RetrySleepWhenFound'
            retry_sleep_when_found_sec = value;
        case 'MessageIfNotFound'
            message_if_not_found = value;
        case 'ErrorIfNotFound'
            error_if_not_found = value;
        otherwise
            vararg_remain{end+1} = name;
            vararg_remain{end+1} = value;            
    end
end


% try to access the file entry
file_non_empty = 0;
dir_entry = dir(filename);

% if it has not been found or if it is empty
if ((isempty(dir_entry)) || (size(dir_entry,1) == 0) || ...
    (dir_entry.bytes <= 0))
    if (message_if_not_found)
        if (isempty(dir_entry))
            fprintf('%s not found',filename);
        else
            fprintf('%s found but of zero length',filename);            
        end
    end
    % retry, if this has been specified
    if (retry_read_sleep_sec > 0.0)
        if (message_if_not_found)
            fprintf(', retrying\n');
        end
        % repeat until found or the specified number of repeats has been
        % exceeded (zero repeats means repeat endlessly)
        retry_read_ct = retry_read_max;
        while ((~file_non_empty) && ...
               ((retry_read_max <= 0) || (retry_read_ct > 0)))
            pause(retry_read_sleep_sec);
            dir_entry = dir(filename);
            if ((~isempty(dir_entry)) && (dir_entry.bytes > 0))
                file_non_empty = 1;
                % workaround option for various problems, 
                % not for permanent use
                if (retry_sleep_when_found_sec > 0)
                    pause(retry_sleep_when_found_sec);
                end
            end
            retry_read_ct = retry_read_ct -1;
        end
    else
        fprintf('\n');
    end
else
    file_non_empty = 1;
end

% open the file for read access
if (file_non_empty)
    fid = fopen(filename,'r');
else
  fid = -1;
end

% exit with an error message, if this has been specified and if the file
% could not be opened 
if (fid < 0)
    if (error_if_not_found)
        error('file ''%s'' not found',filename);
    end
end

% ------------------------------------------------------------------------------

%
% Filename: $RCSfile: cbfread.m,v $
%
% $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
% $Author: farhi $
% $Tag: $
%
% Description:
% Find text signature in a bunch of cell strings from a file header and
% return the following value in the specified format. Example: 
% no_of_bin_bytes = get_hdr_val(header,'X-Binary-Size:','%f',1);
% The last parameter specifies whether the macro should exit with an error
% message if the text signature has not been found. 
%
% Note:
% Call without arguments for a brief help text.
%
% Dependencies:
% none
%
%
% history:
%
% May 7th 2008, Oliver Bunk: 
% add number of input argument check and brief help text
%
% April 25th 2008, Oliver Bunk: 1st version
%
function [outval,line_number,err] = get_hdr_val(header,signature,format,...
    exit_if_not_found)

% initialize output arguments
outval = 0;
line_number = 0;
err = 0;

if (nargin ~= 4)
    fprintf('Usage:\n');
    fprintf('[value,line_number,error]=%s(header,signature,format,exit_if_not_found);\n',...
        mfilename);
    fprintf('header             cell array with text lines as returned by cbfread or ebfread\n');
    fprintf('signature          string to be searched for in the header\n');
    fprintf('format             printf-like format specifier for the interpretation of the value that follows the signature\n');
    fprintf('exit_if_not_found  exit with an error in case either the signature or the value have not been found\n');
    error('Wrong number of input arguments.\n');
end

% search for the signature string
pos_found = strfind(header,signature);

% for sscanf the percentage sign has a special meaning
signature_sscanf = strrep(signature,'%','%%');

% loop over the search results for all header lines
for (ind=1:length(pos_found))
    % if the signature string has been found in this line
    if (length(pos_found{ind}) > 0)
        % get the following value in the specified format
        [outval,count] = sscanf(header{ind}(pos_found{ind}:end),...
            [signature_sscanf format]);
        % return an error if the signature and value combination has not
        % been found (i.e., the format specification did not match)
        if (count < 1)
            outval = 0;
            err = 1;
        else
            % return the first occurrence if more than one has been found
            if (count > 1)
                outval = outval(1);
            end
            % return the line number
            line_number = ind;
            return;
        end
    end
end

% no occurrence found
err = 1;
if (exit_if_not_found)
    error(['no header line with signature ''' signature ''' and format ' ...
        format ' found']);
end

return;


