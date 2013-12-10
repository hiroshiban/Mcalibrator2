%
% Filename: $RCSfile: marread.m,v $
%
% $Revision: 1035 $  $Date: 2013-05-14 17:58:05 +0200 (Tue, 14 May 2013) $
% $Author: farhi $
% $Tag: $
%
% Description:
% Macro for reading TIFF files written by a MAR CCD
%
% Note:
% MAR data are TIFF and can be read by forcing the type to tif. 
% The advantage of forcing the type to mar is, that additional header 
% fields like the exposure time are read. 
% This follows the MarCCD header documentaion by Blum and Doyle
% marccd v0.17.1 
% Call without arguments for a brief help text.
%
% Dependencies:
% - fopen_until_exists
% - get_hdr_val
% - compiling cbf_uncompress.c increases speed but is not mandatory
%
%
% history:
%
% July 17th 2008, Oliver Bunk: 1st version
%

function [frame,vararg_remain] = read_mar(filename,varargin)

% 0: no debug information
% 1: some feedback
% 2: a lot of information
debug_level = 0;

% initialize return argument
frame = struct('header',[], 'data',[]);


% check minimum number of input arguments
if (nargin < 1)
    % image_read_sub_help(mfilename,'mar');
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


% try to open the data file
if (debug_level >= 1)
    fprintf('Opening %s.\n',filename);
end
% [fid,vararg_remain] = fopen_until_exists(filename,vararg);
fid = fopen(filename);
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

% the MAR header has a fixed length of 1024 bytes for the TIFF header plus
% 3072 bytes for the MAR specific part
end_of_header_pos = 4096;

if (length(fdat) < end_of_header_pos)
    error([ num2str(length(fdat)) ' bytes read, which is less than the constant header length' ]);
end

% check little/big endian, also to recognize MAR files
if (typecast(fdat(1025+32:1025+35),'uint32') ~= 1234)
    error([ filename ' is not a MAR file or has big endian byte order' ]);
end

% get image dimensions
nfast = typecast(fdat(1025+80:1025+83),'uint32');
nslow = typecast(fdat(1025+84:1025+87),'uint32');
bytes_per_pixel = typecast(fdat(1025+88:1025+91),'uint32');

if ((bytes_per_pixel ~= 2) && (bytes_per_pixel ~= 4))
    error( [ 'unforseen no. of bytes per pixel of ' num2str(bytes_per_pixel) ] );
end
bytes_expected = end_of_header_pos + nfast*nslow*bytes_per_pixel;
if (bytes_expected ~= length(fdat))
    error([ num2str(bytes_expected) ' bytes expected, ' num2str(length(fdat)) ' read' ]);
end

% return some selected header fields as lines of a cell array
frame.header.IntegrationTime_ms = typecast(fdat(1025+640+12:1025+640+15),'uint32');
frame.header.ExposureTime_ms    = typecast(fdat(1025+640+16:1025+640+19),'uint32');
frame.header.ReadoutTime_ms     = typecast(fdat(1025+640+20:1025+640+23),'uint32');
frame.header.nReads             = typecast(fdat(1025+640+24:1025+640+27),'uint32');
frame.header.Date               = sprintf('%s %s %s:%s%s %s',...
    char(fdat(2369:2370)'),...
    char(fdat(2371:2372)'),...
    char(fdat(2373:2374)'),...
    char(fdat(2375:2376)'),...
    char(fdat(2381:2383)'),...
    char(fdat(2377:2380)'));
frame.header.PixelSizeX_nm      = typecast(fdat(1025+768+4:1025+768+7),'uint32');
frame.header.PixelSizeY_nm      = typecast(fdat(1025+768+8:1025+768+11),'uint32');

% store data
switch bytes_per_pixel
    case 2
        frame.data = typecast(fdat(4097:end),'uint16');
    case 4
        frame.data = typecast(fdat(4097:end),'uint32');
    otherwise
        error( [ 'unforseen no. of bytes per pixel of ' num2str(bytes_per_pixel) ] );
end
frame.data = reshape(frame.data,nfast,nslow);

