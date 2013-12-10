function filename=iData_private_saveas_analyze(a, filename)
% Private function to write Analyze volumes (img+hdr)
%
% Routines adapted from WriteAnalyzeHdr and WriteAnalyzeImg by
% Claus Svarer <csvarer@nru.dk>.
%

if ndims(a) ~= 3 & ndims(a) ~= 4
  filename=[];
  iData_private_warning(mfilename,[ 'Can only export 3D and 4D objects to Analyze format.\n\tObject ' a.Tag ' has ndims=' num2str(ndims(a)) ]);
  return
end

% Split the filename:
[Path,File,Ext]=fileparts(filename);
name=fullfile(Path,File);

% Calculate various stuff
dim=size(a);
siz=zeros(size(dim));

x=getaxis(a,1);
y=getaxis(a,2);
z=getaxis(a,3);
siz(1)=x(2)-x(1); siz(2)=y(2)-y(1); siz(3)=z(2)-z(1);
if ndims(a) == 4
    t=getaxis(a,4);
    siz(4)=t(2)-t(1); 
end

WriteAnalyzeHdr(name,dim,siz,16,[65535 0],1,0,[0 0 0]);
WriteAnalyzeImg(name,get(a,'Signal'),dim,siz,16,[65535 0],1,0,[0 0 0]);

function [result]=WriteAnalyzeHdr(name,dim,siz,pre,lim,scale,offset,origin,descr),
%  Writes the analyze header file 
%
%    [result]=WriteAnalyzeHdr(name,dim,siz,pre,lim,scale,offset,origin[,descr])
%    [result]=WriteAnalyzeHdr(name,dim,siz,pre,lim,scale,offset,origin,descr)
%    [result]=WriteAnalyzeHdr(hdr)
%
%  name      - name of image file
%  dim       - x,y,z,[t] no of pixels in each direction
%  siz       - voxel size in mm
%  pre       - precision for voxels in bit
%                1 - 1 single bit
%                8 - 8 bit voxels (lim is used for deciding if signed or
%                     unsigned char, if min < 0 then signed))
%               16 - 16 bit integer (lim is used for deciding if signed or
%                     unsigned notation should be used, if min < 0 then signed))
%               32 - 32 bit floats
%               32i - 32 bit complex numbers (64 bit pr. voxel)
%               64 - 64 bit floats
%  lim       - max and min limits for pixel values (ex: [255 0] for 8 bit)
%  scale     - scale is scaling of pixel values
%  offset    - offset is offset in pixel values
%  origin    - origin for AC-PC plane
%  descr     - description of file, scan
%
%  hdr       - structure with all the fields mentionened above plus
%               path - path for file
%               endian - defaults to big endian, can be overwritten 
%               using this field
%
%  abs_pix_val = (pix_val - offset) * scale
%
%  CS, 130398
%  CS, 280100  Reading changed so routines works on both HP and Linux
%              systems
%  CS, 150200  Extended to be able to use descrion field
%  CS, 060700  Structure input (hdr) extended as possibility
%  CS, 210901  Extended with extra 'path' field in stucture hdr
%  PW, 300402  Extended with extra 'endian' field in structure hdr
%
if (nargin ~=1) & (nargin ~= 8) & (nargin ~= 9)
   ErrTxt=sprintf('WriteAnalyzeHdr, (%i) is an incorrect number of input arguments',nargin);
   error(ErrTxt);
end;
if (nargin == 8)
  descr='Header generated using WriteAnalyzeHdr';
end
if (nargin == 8) | (nargin == 9)
  path='';
end  
% 
% Default endianness:
%
endian='ieee-be';

if (nargin == 1)
  hdr=name;
  %
  if (~isfield(hdr,'name'))
    error('hdr.name does not exist');
  end;
  name=hdr.name;
  if (~isfield(hdr,'dim'))
    error('hdr.dim does not exist');
  end;
  dim=hdr.dim;
  if (~isfield(hdr,'siz'))
    error('hdr.siz does not exist');
  end;
  siz=hdr.siz;
  if (~isfield(hdr,'pre'))
    error('hdr.pre does not exist');
  end;
  pre=hdr.pre;
  if (~isfield(hdr,'lim'))
    error('hdr.lim does not exist');
  end;
  lim=hdr.lim;
  if (~isfield(hdr,'scale'))
    error('hdr.scale does not exist');
  end;
  scale=hdr.scale;
  if (~isfield(hdr,'offset'))
    error('hdr.offset does not exist');
  end;
  offset=hdr.offset;
  if (~isfield(hdr,'origin'))
    origin=[0 0 0];
  else  
    origin=hdr.origin;
  end;
  if (~isfield(hdr,'descr'))
    descr='Header generated using WriteAnalyzeHdr';
  else  
    descr=hdr.descr;
  end;
  if isfield(hdr,'endian')
    endian=hdr.endian;
  end
  if (~isfield(hdr,'path')) | ...
    ~isempty(findstr(hdr.name,'/')) | ... 
    ~isempty(findstr(hdr.name,'\')) 
    path='';
  else  
    path=hdr.path;
    if ~isempty(path)
      cname = computer;
      if strcmp(cname(1:2),'PC')
        if (path(length(path)) ~= '\')
          path(length(path)+1) ='\';
        end
      else  
        if (path(length(path)) ~= '/')
          path(length(path)+1) ='/';
        end
      end
    end  
  end;
end
%
if (length(dim) == 3)
  dim(4)=1;
end;  
result=1;
FileName=sprintf('%s%s.hdr',path,name);
pid=fopen(FileName,'wb',endian);
%
fwrite(pid,348,'int');
fwrite(pid,zeros(28,1),'char');
fwrite(pid,16384,'int');
fwrite(pid,zeros(2,1),'char');
fwrite(pid,'r','char');
fwrite(pid,zeros(1,1),'char');

fwrite(pid,4,'int16');
fwrite(pid,dim,'int16');
fwrite(pid,zeros(20,1),'char');

if ~isreal(pre)                    % Complex number (2x32 bit float)
  pre=imag(pre);
  if (pre~=32)
    error('Only 32 bit float can be written as complex numbers');
  else
    fwrite(pid,32,'int16');
    BitPix=64;
  end      
elseif (pre == 1),                 % binary (single bit)
  fwrite(pid,1,'int16');
  BitPix=1;
elseif (pre == 8),                 % 8 bit unsigned char
  fwrite(pid,2,'int16');
  BitPix=8;
elseif (pre == 16),                % 16 bit signed integer
  fwrite(pid,4,'int16');
  BitPix=16;
elseif (pre == 32),                % 32 bit float
  fwrite(pid,16,'int16');
  BitPix=32;
elseif (pre == 64),                % 64 bit float
  fwrite(pid,64,'int16');
  BitPix=64;
else
  error('WriteAnalyzeHdr, pre parameter do not have allowable value');
end  

fwrite(pid,BitPix,'int16');

fwrite(pid,zeros(6,1),'char');

if (length(siz) ~= 3)
  error('WriteAnalyzeHdr, siz parameter do not have allowable value');
end;  
fwrite(pid,siz,'float32');

fwrite(pid,zeros(16,1),'char');
fwrite(pid,offset,'float32');
fwrite(pid,scale,'float32');
fwrite(pid,zeros(24,1),'char');

fwrite(pid,lim(1),'int');
fwrite(pid,lim(2),'int');

descr(80)=0;
fwrite(pid,sprintf('%-80s',descr),'char');

fwrite(pid,zeros(24,1),'char');
fwrite(pid,0,'char');  % orientation

if (length(origin) ~= 3)
  error('WriteAnalyzeHdr, origin parameter do not have allowable value');
end;  
fwrite(pid,origin,'int16');  

fwrite(pid,zeros(89,1),'char'); 

fclose(pid);

function [result]=WriteAnalyzeImg(name,img,dim,siz,pre,lim,scale,offset,origin,descr)
%  Writes analyze image and header file 
%
%    [result]=WriteAnalyzeImg(name,img,dim,siz,pre,lim,scale,offset)
%    [result]=WriteAnalyzeImg(name,img,dim,siz,pre,lim,scale,offset,origin)
%    [result]=WriteAnalyzeImg(name,img,dim,siz,pre,lim,scale,offset,origin,descr)
%    [result]=WriteAnalyzeImg(name,img,dim,siz,pre,lim,'a') (automatic scaling/offset)
%    [result]=WriteAnalyzeImg(hdr,img)
%
%  name      - name of image file
%  img       - image data (pix_val)
%  dim       - x,y,z,[t] no of pixels in each direction
%  siz       - voxel size in mm
%  pre       - precision for pictures (8 or 16)
%  lim       - max and min limits for pixel values (ex: [255 0] for 8 bit)
%  scale     - scale is scaling of pixel values
%  offset    - offset is offset in pixel values
%  origin    - origin for AC-PC plane
%  descr     - description field in header file
%
%  hdr       - header structure (as defined for WriteAnalyzeHdr) plus
%               path - filed with path for file
%               endian - defaults to big endian, can be overwritten 
%               using this field
%
%  abs_pix_val = (pix_val - offset) * scale
%
%  CS, 010294
%
%  Revised
%  CS, 181194  Possibility of offset and scale in header file
%  CS, 300398  Origin included
%  CS, 280100  Reading changed so routines works on both HP and Linux
%              systems
%  CS, 150200  Extended with description field
%  CS, 060700  writing routine extended to handle structure header
%              information
%  CS, 210901  Extended with extra field 'path' in structure hdr
%  PW; 200402  Extended with extra field 'endian' in structure hdr
%
if (nargin ~= 7) & (nargin ~= 8) & (nargin ~= 9) & (nargin ~= 10) ...
      & (nargin ~= 2) 
   error('WriteAnalyze, incorrect number of input arguments');
end;
% 
% Default endianness:
%
endian='ieee-be';
if (nargin == 2)
  hdr=name;
  %
  if (~isfield(hdr,'name'))
    error('hdr.name does not exist');
  end;
  name=hdr.name;
  if (~isfield(hdr,'dim'))
    error('hdr.dim does not exist');
  end;
  dim=hdr.dim;
  if (~isfield(hdr,'siz'))
    error('hdr.siz does not exist');
  end;
  siz=hdr.siz;
  if (~isfield(hdr,'pre'))
    error('hdr.pre does not exist');
  end;
  pre=hdr.pre;
  if (~isfield(hdr,'lim'))
    error('hdr.lim does not exist');
  end;
  lim=hdr.lim;
  if (~isfield(hdr,'scale'))
    error('hdr.scale does not exist');
  end;
  scale=hdr.scale;
  if (~isfield(hdr,'offset'))
    error('hdr.offset does not exist');
  end;
  offset=hdr.offset;
  if (~isfield(hdr,'origin'))
    origin=[0 0 0];
  else  
    origin=hdr.origin;
  end;
  if (~isfield(hdr,'descr'))
    descr='Header generated using WriteAnalyzeHdr';
  else  
    descr=hdr.descr;
  end;
  if isfield(hdr,'endian')
    endian=hdr.endian;
  end
  if (~isfield(hdr,'path')) | ...
    ~isempty(findstr(hdr.name,'/')) | ... 
    ~isempty(findstr(hdr.name,'\')) 
    path='';
  else  
    path=hdr.path;
    if ~isempty(path)
      cname = computer;
      if strcmp(cname(1:2),'PC')
        if (path(length(path)) ~= '\')
          path(length(path)+1) ='\';
        end
      else  
        if (path(length(path)) ~= '/')
          path(length(path)+1) ='/';
        end
      end
    end  
  end;
else
  path='';
end
%
if (length(dim) == 3)
  dim(4)=1;
end;
auto = 0;  % Ikke automatisk skalering
if (nargin == 7)
   if (scale == 'a')
      auto = 1;
      if (pre == 8)
         scale = (max(max(img)) - min(min(img))) / 256;
         img = img / scale;
         offset = - min(min(img));
         img = img + offset;
         offset = offset - 0.5;
         index = find(img == 256);
         for i=1:length(index)
            img(index(i)) = 255;
         end;
      else
         if (lim(2) < 0)
            offset = 0;
            scale1 = max(max(img)) / 32767;
            scale2 = min(min(img)) / (-32768);
            scale = max([scale1 scale2]);
            img = img / scale;
         else   
            scale = (max(max(img)) - min(min(img))) / 65536;
            img = img / scale;
            offset = - min(min(img));
            img = img + offset;
            offset = offset - 0.5;
            index = find(img == 65536);
            for i=1:length(index)
               img(index(i)) = 65535;
            end;
         end;
      end; 
   else
   error('Not automatic scaling, but only 7 parameters');
   end;
end;
result=1;
%
pos=findstr(name,'.img');
if (~isempty(pos))
  name=name(1:(pos(1)-1));
  hdr.name=name;
end;  
pos=findstr(name,'.hdr');
if (~isempty(pos))
  name=name(1:(pos(1)-1));
  hdr.name=name;
end;
%
FileName=sprintf('%s%s.img',path,name);
pid=fopen(FileName,'wb',endian);
if (pid ~= -1),
   if (pre == 8),
     fwrite(pid,img,'uint8');
   elseif (pre == 16),
     if (lim(2) < 0)
       f=fwrite(pid,img,'int16');
     else
       f=fwrite(pid,img,'uint16');
     end
   elseif (pre == 32)  
     f=fwrite(pid,img,'float32');
   elseif (pre == 64)  
     f=fwrite(pid,img,'float64');
   else
     error('Illegal precision');
   end;  
   %    
   if (nargin == 6),
     scale=0;
     offset=0;
     origin=[0 0 0];
   elseif (nargin == 7) & (auto == 0),
     offset=0;
     origin=[0 0 0];
   elseif (nargin == 8) & (auto == 0),
     origin=[0 0 0];
   else
     % All parameters defined
   end;
   if (nargin == 2)
      WriteAnalyzeHdr(hdr);
   elseif (nargin == 10)
      WriteAnalyzeHdr(name,dim,siz,pre,lim,scale,offset,origin,descr);
   else
      WriteAnalyzeHdr(name,dim,siz,pre,lim,scale,offset,origin);
   end
else
   result=0;
   fprintf('WriteAnalyze, Not possible to open image file\n'); 
end;      
fclose(pid);










