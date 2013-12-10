function data = read_nii(filename)
% read a NifTi Neuroimaging Informatics Technology Initiative volume
%
% <http://nifti.nimh.nih.gov/>
% 
% Extracted from: <http://www.mathworks.com/matlabcentral/fileexchange/29344-read-medical-data-3d>
%  by Dirk-Jan Kroon 10 Nov 2010 (Updated 23 Feb 2011) 

data = [];

info = nii_read_header(filename);
if ~isempty(info)
  data.Header = info;
  data.Image  = nii_read_volume(info);
end

function [info] = nii_read_header(filename)
% function for reading header of NifTi ( .nii ) volume file
%
% info = nii_read_header(filename);
%
% examples:
% 1,  info=nii_read_header()
% 2,  info=nii_read_header('volume.nii');

if(exist('filename','var')==0)
     [filename, pathname] = uigetfile('*.nii', 'Read nii-file');
     filename = [pathname filename];
end

bswap=false;
test=true;
while(test)
    if(bswap)
        fid=fopen(filename,'rb','b');
    else
        fid=fopen(filename,'rb','l');
    end    
    if(fid<0)
         fprintf('could not open file %s\n',filename);
         return
    end

    %get the file size
    fseek(fid,0,'eof');
    info.Filesize = ftell(fid); 
    fseek(fid,0,'bof');
    info.Filename=filename;
    info.SizeofHdr=fread(fid,1,'int');
    info.DataType=fread(fid, 10, 'uint8=>char')';
    info.DbName=fread(fid, 18, 'uint8=>char')';
    info.Extents=fread(fid,1,'int');
    info.SessionError=fread(fid,1,'uint16');
    info.Regular=fread(fid, 1, 'uint8=>char')';
    info.DimInfo=fread(fid, 1, 'uint8=>char')';
    swaptemp=fread(fid, 1, 'uint16')';
    info.Dimensions=fread(fid,7,'uint16')'; % dim = [ number of dimensions x,y,z,t,c1,c2,c3];
	
    if(swaptemp(1)<1||swaptemp(1)>7), bswap=true; fclose(fid); else test=false; end
end
info.headerbswap=bswap;
info.IntentP1=fread(fid,1,'float');
info.IntentP2=fread(fid,1,'float');
info.IntentP3=fread(fid,1,'float');
info.IntentCode=fread(fid,1,'uint16');
info.DataType=fread(fid,1,'uint16');
datatypestr{1}={0,'UNKNOWN',  0}; % what it says, dude           
datatypestr{2}={1,'BINARY',   1}; % binary (1 bit/voxel)         
datatypestr{3}={2,'UINT8'  ,  8};% unsigned char (8 bits/voxel) 
datatypestr{4}={4,'INT16'   , 16}; % signed short (16 bits/voxel) 
datatypestr{5}={8,'INT32'  ,  32}; % signed int (32 bits/voxel)   
datatypestr{6}={16,'FLOAT' ,  32}; % float (32 bits/voxel)        
datatypestr{7}={32,'COMPLEX', 64}; % complex (64 bits/voxel)      
datatypestr{8}={64,'DOUBLE',  64}; % double (64 bits/voxel)       
datatypestr{9}={128,'RGB'  ,  24}; % RGB triple (24 bits/voxel)   
datatypestr{10}={255,'ALL'  ,  0}; % not very useful (?)          
datatypestr{11}={256,'INT8' ,  8}; % signed char (8 bits)         
datatypestr{12}={512,'UINT16', 16}; % unsigned short (16 bits)     
datatypestr{13}={768,'UINT32', 32}; % unsigned int (32 bits)       
datatypestr{14}={1024,'INT64', 64}; % long long (64 bits)          
datatypestr{15}={1280,'UINT64',     64}; % unsigned long long (64 bits) 
datatypestr{16}={1536,'FLOAT128',   128}; % long double (128 bits)       
datatypestr{17}={1792,'COMPLEX128', 128}; % double pair (128 bits)       
datatypestr{18}={2048,'COMPLEX256', 256}; % long double pair (256 bits)  
datatypestr{19}={2304,'RGBA32', 32}; % 4 byte RGBA (32 bits/voxel) 
info.datatypestr='UNKNOWN';
info.bitvoxel=0;
for i=1:19
    if(datatypestr{i}{1}==info.DataType)
        info.DataTypeStr=datatypestr{i}{2};
        info.BitVoxel=datatypestr{i}{3};
    end
end

info.Bitpix=fread(fid,1,'uint16');
info.SliceStart=fread(fid,1,'uint16');
temp=fread(fid,1,'float');
info.PixelDimensions=fread(fid,7,'float');

info.VoxOffset=fread(fid,1,'float');
info.RescaleSlope=fread(fid,1,'float');
info.RescaleIntercept=fread(fid,1,'float');
info.SliceEnd=fread(fid,1,'uint16');
info.SliceCode=fread(fid, 1, 'uint8=>char')';
info.XyztUnits=fread(fid, 1, 'uint8')';
dataunitsstr{1}={'UNKNOWN', 0}; %! NIFTI code for unspecified units. 
dataunitsstr{2}={'METER',   1};  %! NIFTI code for meters. 
dataunitsstr{3}={'MM',    2};  %! NIFTI code for millimeters. 
dataunitsstr{4}={'MICRON ', 3};  %! NIFTI code for micrometers. 
dataunitsstr{5}={'SEC',    8};  %! NIFTI code for seconds. 
dataunitsstr{6}={'MSEC',   16};  %! NIFTI code for milliseconds. 
dataunitsstr{7}={'USEC',  24};  %! NIFTI code for microseconds. 
dataunitsstr{8}={'HZ',  32};  %! NIFTI code for Hertz. 
dataunitsstr{9}={'PPM',  40};  %! NIFTI code for ppm. 
dataunitsstr{10}={'RADS',  48};  %! NIFTI code for radians per second. 
info.xyzt_unitsstr='UNKNOWN';
for i=1:10,
    if(dataunitsstr{i}{2}==info.XyztUnits)
        info.XyztUnitsStr=dataunitsstr{i}{1};
    end
end

info.CalMax=fread(fid,1,'float');
info.CalMin=fread(fid,1,'float');
info.Slice_duration=fread(fid,1,'float');
info.Toffset=fread(fid,1,'float');
info.Glmax=fread(fid,1,'int');
info.Glmin=fread(fid,1,'int');
info.Descrip=fread(fid, 80, 'uint8=>char')';
info.AuxFile=fread(fid, 24, 'uint8=>char')';
info.QformCode=fread(fid,1,'uint16');
info.SformCode=fread(fid,1,'uint16');
info.QuaternB=fread(fid,1,'float');
info.QuaternC=fread(fid,1,'float');
info.QuaternD=fread(fid,1,'float');
info.QoffsetX=fread(fid,1,'float');
info.QoffsetY=fread(fid,1,'float');
info.QoffsetZ=fread(fid,1,'float');
info.SrowX=fread(fid,4,'float');
info.SrowY=fread(fid,4,'float');
info.SrowZ=fread(fid,4,'float');
info.IntentName=fread(fid, 16, 'uint8=>char')';
info.Magic=fread(fid, 4, 'uint8=>char')';
if ~strncmp(info.Magic, 'nii', 3) && ~strncmp(info.Magic, 'n+1', 3)
  error([ mfilename ': ' filename ' is probably not a NifTI volume file.' ])
end

fclose(fid);

% ------------------------------------------------------------------------------
function V = nii_read_volume(info)
% function for reading volume of NifTi ( .nii ) volume file
% nii_read_header(file-info)
%
% volume = nii_read_volume(file-header)
%
% examples:
% 1: info = nii_read_header()
%    V = nii_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = nii_read_volume('test.nii');

if(~isstruct(info)) info=nii_read_header(info); end

% Open v3d file
fid=fopen(info.Filename,'rb');

  % Seek volume data start
  datasize=prod(info.Dimensions)*(info.BitVoxel/8);
  fsize=info.Filesize;
  fseek(fid,fsize-datasize,'bof');

  % Read Volume data
  switch(info.DataTypeStr)
      case 'INT8'
        V = int8(fread(fid,datasize,'int8'));
      case 'UINT8'
        V = uint8(fread(fid,datasize,'uint8'));
      case 'INT16'
        V = int16(fread(fid,datasize,'int16'));
      case 'UINT16'
        V = uint16(fread(fid,datasize,'uint16'));
      case 'INT32'
        V = int32(fread(fid,datasize,'int32'));
      case 'UINT32'
        V = uint32(fread(fid,datasize,'uint32'));
      case 'INT64'
        V = int64(fread(fid,datasize,'int64'));
      case 'UINT64'
        V = uint64(fread(fid,datasize,'uint64'));    
      otherwise
        V = uint8(fread(fid,datasize,'uint8'));
  end
fclose(fid);

% Reshape the volume data to the right dimensions
V = reshape(V,info.Dimensions);

