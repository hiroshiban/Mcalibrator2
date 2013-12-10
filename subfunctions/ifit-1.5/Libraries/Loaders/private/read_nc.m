function S = read_nc(File,varargin)
  % read a NetCDF file, using 2 methods
  
  try
    % a NetCDF reader using netcdf lib (faster)
    S = read_nc2(File);
  catch
    % a basic NC reader that does not make use of the nc library, but is limited to NC1
    S = read_nc1(File);
  end
  
% ______________________________________________________________________________

function obj = read_nc2(File)
% inspired from netcdfobj contribution on Matlab Central.
% 

  % open the file
  fid = netcdf.open(File);
  obj = struct();
  
  obj.Name       = '/';
  obj.Filename   = File;
  obj.Group      = [];
  obj.Format     = netcdf.inqFormat(fid);
  obj.NetCDF_Version = netcdf.inqLibVers;
   
  % inquire global dimensions
  [nd,nvars,natts,unlimdimID]= netcdf.inq(fid);
  % now read the underlying structure dimension: obj.Dimensions(:) = struct(Name, Length)
  obj.Dimensions = [];
  for ii=1:nd
    [name, len]        = netcdf.inqDim(fid,ii-1);
    Dimension = struct('Name', name, 'Length', len);
    if isempty(obj.Dimensions)
      obj.Dimensions = Dimension;
    else
      obj.Dimensions(end+1) = Dimension ;
    end
  end
  
  % get global attributes
  obj.Attributes = [];
  jj = 1;
  while 1
    try
      Attribute.Name  = netcdf.inqAttName(fid,netcdf.getConstant('NC_GLOBAL'),jj-1);
      Attribute.Value = netcdf.getAtt(fid,netcdf.getConstant('NC_GLOBAL'),Attribute.Name);
      if isempty(obj.Attributes)
        obj.Attributes = Attribute;
      else
        obj.Attributes(end+1) = Attribute;
      end
      jj = jj + 1;
    catch
      break; % no more global Attribute
    end
  end

  % now read variables: obj.Variables.Name
  obj.Variables = [];
  for ii=1:nvars
      [Variable.Name, Variable.Datatype, dimids, numatts] = ...
        netcdf.inqVar(fid,ii-1); % get all meta data
      Variable.Data = netcdf.getVar(fid,ii-1);   % get value
      
      % get variable attributes: obj.Variables(:).Attributes = struct(Name, Value)
      Variable.Attributes = [];
      for jj=1:numatts
         Attribute.Name =netcdf.inqAttName(fid,ii-1,jj-1);
         Attribute.Value=netcdf.getAtt(fid,ii-1,Attribute.Name);
         if isempty(Variable.Attributes)
           Variable.Attributes = Attribute;
         else
           Variable.Attributes(end+1) = Attribute;
         end
      end
      % store the Variable and Attribute into obj
      flag = 0; % set when we manage to store the variable
      if any(Variable.Name == '.') && ~any(isspace(Variable.Name))
        try
          eval([ 'obj.Variables.'  Variable.Name '= Variable.Data;' ]);
          eval([ 'obj.Attributes.' Variable.Name '= Attribute;' ]);
          flag = 2;   % assign through eval (this_field = 'blah.blah.blah')
        end
      end
      if flag == 0
        Variable.Name = genvarname(Variable.Name);
        obj.Variables.(Variable.Name)  = Variable.Data;
        obj.Attributes.(Variable.Name) = Attribute;
        flag = 1;
      end
  end
  
  % close the file
  netcdf.close(fid);

% ______________________________________________________________________________

function S = read_nc1(File, varargin)
% Function to read NetCDF files
%   S = netcdf(File)
% Input Arguments
%   File = NetCDF file to read
% Optional Input Arguments:
%   'Var',Var - Read data for VarArray(Var), default [1:length(S.VarArray)]
%   'Rec',Rec - Read data for Record(Rec), default [1:S.NumRecs]
% Output Arguments:
%   S    = Structure of NetCDF data organised as per NetCDF definition
% Notes:
%   Only version 1, classic 32bit, NetCDF files are supported. By default
% data are extracted into the S.VarArray().Data field for all variables.
% To read the header only call S = netcdf(File,'Var',[]);
%
% SEE ALSO
% ---------------------------------------------------------------------------

% by Paul Spencer
% 02 Jun 2007 (Updated 05 Jun 2007) 

%  Copyright (c) 2009, Paul Spencer
%  All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are
%  met:
%
%      * Redistributions of source code must retain the above copyright
%        notice, this list of conditions and the following disclaimer.
%      * Redistributions in binary form must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in
%        the documentation and/or other materials provided with the distribution
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%  POSSIBILITY OF SUCH DAMAGE.

S = [];

try
   if exist(File,'file') fp = fopen(File,'r','b');
   else fp = []; error('File not found'); end
   if fp == -1   error('Unable to open file'); end

% Read header
   Magic = fread(fp,4,'uint8=>char');
   if strcmp(Magic(1:3),'CDF') error('Not a NetCDF file'); end
   if uint8(Magic(4))~=1       error('Version not supported'); end
   % use a structure compatible with 'ncinfo'
   S.Name       = '/';
   S.Filename   = File;
   S.Group      = [];
   S.Format     = 'FORMAT_CLASSIC';
   S.NumRecs  = fread(fp,1,'uint32=>uint32');
   S.Dimensions = DimArray(fp);
   S.Attributes = AttArray(fp);
   S.Variables  = VarArray(fp);
   

% Setup indexing to arrays and records
   Var = ones(1,length(S.Variables));
   Rec = ones(1,S.NumRecs);
   for i = 1:2:length(varargin)
      if     strcmp(upper(varargin{i}),'VAR') Var=Var*0; Var(varargin{i+1})=1;
      elseif strcmp(upper(varargin{i}),'REC') Rec=Rec*0; Rec(varargin{i+1})=1;
      else error('Optional input argument not recognised'); end
   end
   if sum(Var)==0 fclose(fp); return; end

% Read non-record variables
   Dim = double(cat(2,S.Dimensions.Length));
   ID  = double(cat(2,S.Variables.Datatype));

   for i = 1:length(S.Variables)
      D = Dim(S.Variables(i).Size+1); N = prod(D); RecID{i}=find(D==0);
      if isempty(RecID{i})
         if length(D)==0 D = [1,1]; N = 1; elseif length(D)==1 D=[D,1]; end
         if Var(i)
            S.Variables(i).Data = ReOrder(fread(fp,N,[Type(ID(i)),'=>',Type(ID(i))]),D);
            fread(fp,(Pad(N,ID(i))-N)*Size(ID(i)),'uint8=>uint8');
         else fseek(fp,Pad(N,ID(i))*Size(ID(i)),'cof'); end
      else S.Variables(i).Data = []; end
   end

% Read record variables
   for k = 1:S.NumRecs
      for i = 1:length(S.Variables)
         if ~isempty(RecID{i})
            D = Dim(S.Variables(i).Size+1); D(RecID{i}) = 1; N = prod(D);
            if length(D)==1 D=[D,1]; end
            if Var(i) & Rec(k)
               S.Variables(i).Data = cat(RecID{i},S.Variables(i).Data,...
                  ReOrder(fread(fp,N,[Type(ID(i)),'=>',Type(ID(i))]),D));
               if N > 1 fread(fp,(Pad(N,ID(i))-N)*Size(ID(i)),'uint8=>uint8'); end
            else fseek(fp,Pad(N,ID(i))*Size(ID(i)),'cof'); end
         end
      end
   end

   fclose(fp);
catch
   Err = lasterror; fprintf('%s\n',Err.message);
   if ~isempty(fp) && fp ~= -1 fclose(fp); end
end

% ---------------------------------------------------------------------------------------
% Utility functions

function S = Size(ID)
% Size of NetCDF data type, ID, in bytes
   S = subsref([1,1,2,4,4,8],struct('type','()','subs',{{ID}}));

function T = Type(ID)
% Matlab string for CDF data type, ID
   T = subsref({'int8','char','int16','int32','single','double'},...
               struct('type','{}','subs',{{ID}}));

function N = Pad(Num,ID)
% Number of elements to read after padding to 4 bytes for type ID
   N = (double(Num) + mod(4-double(Num)*Size(ID),4)/Size(ID)).*(Num~=0);

function S = String(fp)
% Read a CDF string; Size,[String,[Padding]]
   S = fread(fp,Pad(fread(fp,1,'uint32=>uint32'),1),'uint8=>char').';

function A = ReOrder(A,S)
% Rearrange CDF array A to size S with matlab ordering
   A = permute(reshape(A,fliplr(S)),fliplr(1:length(S)));

function S = DimArray(fp)
% Read DimArray into structure
   if fread(fp,1,'uint32=>uint32') == 10 % NC_DIMENSION
      for i = 1:fread(fp,1,'uint32=>uint32')
         S(i).Name = String(fp);
         S(i).Length = fread(fp,1,'uint32=>uint32');
      end
   else fread(fp,1,'uint32=>uint32'); S = []; end

function S = AttArray(fp)
% Read AttArray into structure
   if fread(fp,1,'uint32=>uint32') == 12 % NC_ATTRIBUTE
      for i = 1:fread(fp,1,'uint32=>uint32')
         S(i).Name = String(fp);
         ID       = fread(fp,1,'uint32=>uint32');
         Num      = fread(fp,1,'uint32=>uint32');
         S(i).Value = fread(fp,Pad(Num,ID),[Type(ID),'=>',Type(ID)]).';
      end
   else fread(fp,1,'uint32=>uint32'); S = []; end

function S = VarArray(fp)
% Read VarArray into structure
   if fread(fp,1,'uint32=>uint32') == 11 % NC_VARIABLE
      for i = 1:fread(fp,1,'uint32=>uint32')
         S(i).Name      = String(fp);
         Num           = double(fread(fp,1,'uint32=>uint32'));
         S(i).Size     = double(fread(fp,Num,'uint32=>uint32'));
         S(i).Attributes = AttArray(fp);
         S(i).Datatype     = fread(fp,1,'uint32=>uint32');
         S(i).ChunkSSize    = fread(fp,1,'uint32=>uint32');
         S(i).Begin    = fread(fp,1,'uint32=>uint32'); % Classic 32 bit format only
      end
   else fread(fp,1,'uint32=>uint32'); S = []; end
