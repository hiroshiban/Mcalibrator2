function out = load(a, varargin)
% d = load(s, file, loader, ...): iData file loader
%
%   @iData/load: imports any data into Matlab/iData object(s)
%   The input argument 'file' should be a file name, or a cell of file names, 
%     or any Matlab variable, or empty (then popup a file selector).
%   The choice of the data file importer is set by default to automatic, so
%     that most common data importers are tested until one works. User may configure
%     a list of prefered loader definitions in a file called iData_load_ini.
%   The optional 3rd argument can be set to use a specific loader list (see below)
%     load(iData, filename, loader)
%   The input iData object is updated if no output argument is specified.
%
%   Default supported formats include: any text based including CSV, Lotus1-2-3, SUN sound, 
%     WAV sound, AVI movie, NetCDF, FITS, XLS, BMP GIF JPEG TIFF PNG ICO images,
%     HDF4, HDF5, MAT workspace, XML, CDF, JSON, YAML
%   Other specialized formats include: McStas, ILL, SPEC, ISIS/SPE, INX, EDF, Mantid.
%     SIF, MCCD/TIFF, ADSC, CBF, Analyze, NifTI, STL,PLY,OFF, CIF/CFL,
%     EZD/CCP4, NMR formats
%   Compressed files are also supported, with on-the-fly extraction (zip, gz, tar, Z).
%   Distant files are supported through e.g. URLs such as 
%     file://, ftp://, http:// and https://
%   File names may end with an internal anchor reference '#anchor", as used in HTML 
%     links, in which case the members matching the anchor are returned.
%
%  Type <a href="matlab:doc(iData,'Load')">doc(iData,'Load')</a> to access the iFit/Load Documentation.
%
% input:  s: object or array (iData)
%         file: file name(s) to import (char/cellstr)
%         loader: optional loader method specification (char/struct/cellstr/array of struct)
%               loader = 'auto' (default) test all known data readers until one works
%               loader = 'gui'  manually ask user for the loader(s) to use
%             OR a function name to use as import routine, OR a struct/cell of struct with:
%               loader.method     = function to read data file (char/function_handle)
%               loader.options    = options (char/cell which is then expanded)
%               loader.postprocess= function to act on freshly imported iData (char/function_handle)
%         additional arguments are passed to the import routine.
%
% The loading process calls first
%   data =loader.method(filename, options...)
% then build the iData object, and optionally calls
%   iData=loader.postprocess(iData)
%
% output: d: single object or array (iData)
% ex:     load(iData,'file'); load(iData); load(iData, 'file', 'gui'); load(a,'','looktxt')
%         load(iData, [ ifitpath 'Data/peaks.hdf5' ], 'HDF')
%         load(iData, 'http://file.gz#Data')
%
% Version: $Revision: 1158 $
% See also: iLoad, save, iData/saveas, Loaders

% calls private/iLoad
% iLoad returns nearly an iData structure.
% inline: load_check_struct
% EF 23/09/07 iData implementation

[files, loaders] = iLoad(varargin{:}); % import files as structures HERE

if isempty(files), out=[]; return; end
if isstruct(files) && length(files) == 1 && isfield(files,'loaders')
    out=files;
    return;
end
if ~iscell(files),   files   = { files }; end
if ~iscell(loaders), loaders = { loaders }; end
out = [];

for i=1:numel(files)
  filename = '';
  if isempty(files{i}), continue; end
  if length(varargin) >= 1 && ischar(varargin{1}), filename = varargin{1}; end
  if isstruct(files{i}) && isempty(filename)
    f = fieldnames(files{i});
    index = [ find(strcmpi(f,'filename'),1) ;find(strcmpi(f,'file_name'),1) ;find(strcmpi(f,'source'),1) ];
    if ~isempty(index)
      filename = files{i}.(f{index(1)}); 
    end
  end
  
  % check the returned iLoad structure
  files{i} = load_check_struct(files{i}, loaders, filename);
  if isfield(files{i},'Data') && isstruct(files{i}.Data) && any(cellfun('isclass', struct2cell(files{i}.Data), 'iData'))
    % a structure containing an iData
    this_iData = [];
    struct_data = struct2cell(files{i}.Data);
    files{i} = {};  % free memory
    for index=1:length(struct_data)
      if isa(struct_data{index}, 'iData')
        if isa(struct_data{index}.Data, 'uint8')
          struct_data{index}.Data = hlp_deserialize(struct_data{index}.Data);
        end
        this_iData = [ this_iData struct_data{index} ];
        struct_data{index} = '';
      end
    end
    clear struct_data
  else
    % usually a structure from iLoad

    % convert file content from iLoad into iData
    this_iData = iData_struct2iData(files{i});	
    % assign default Signal and axes
    this_iData = iData_check(this_iData);
    % post-processing
    if ~isempty(this_iData)
      if isempty(loaders) || ~isfield(loaders{i}, 'postprocess')
        loaders{i}.postprocess='';
      end
      if isempty(loaders{i}.postprocess) && isfield(files{i},'Loader')
        if isfield(files{i}.Loader, 'postprocess')
          loaders{i}.postprocess = files{i}.Loader.postprocess;
        end
      end
      files{i} = {};  % free memory
      if ~isempty(loaders{i}.postprocess)
        % remove warnings
        iData_private_warning('enter',mfilename);
        if ~iscell(loaders{i}.postprocess)
          loaders{i}.postprocess = cellstr(loaders{i}.postprocess);
        end
        % apply post-load routine: this may generate more data sets
        for j=1:length(loaders{i}.postprocess)
          if ~isempty(loaders{i}.postprocess{j})
            % call private method (see below)
            this_iData = load_eval_postprocess(this_iData, loaders{i}.postprocess{j});
          end
        end
        % reset warnings
        iData_private_warning('exit',mfilename);
      elseif ~isempty(loaders{i}.postprocess)
        iData_private_warning(mfilename,['Can not find post-process function ' loaders{i}.postprocess ' for data format ' loaders{i}.name ]);
      end
    end
  end
  % transpose to make columns
  if numel(out) > 1 && size(out,2) > 1 && size(out,1) == 1, out=out'; end
  if numel(this_iData) > 1 && size(this_iData,2) > 1 && size(this_iData,1) == 1, this_iData=this_iData'; end
  out = [ out ; this_iData ];
  clear this_iData
end %for i=1:length(files)

% clean 'out' for unique entries (e.g. mcstas/mcstas.sim creates duplicates)
[b, i1] = unique(get(out, 'Source')); % name is unique
if 1 < length(out) && length(i1) < length(out)
  % some data sets seem to be duplicated: make additional tests
  % look for similarities
  sources = get(out, 'Source');
  titls   = get(out, 'Title');
  labs    = get(out, 'Label');
  i       = 1:length(out);
  for index=1:length(out)
    j = find(strcmp(sources{index}, sources) & strcmp(titls{index}, titls) & strcmp(labs{index}, labs));
    if length(j) > 1, i(j(2:end)) = 0; end
  end
  i = unique(i(i>0));
  if length(out) > length(i)
    disp(sprintf('Removing duplicated data sets %i -> %i', length(out), length(i)))
    out = out(i);
  end
end

for i=1:numel(out)
  out(i).Command{end+1}=[ out(i).Tag '=load(iData,''' out(i).Source ''');' ];
  if isempty(out(i).DisplayName) && isempty(out(i).Label)
    [p,f,e] = fileparts(out(i).Source);
    out(i) = set(out(i),'Label',[ f e ]);
  end
  %this_iData = iData_private_history(this_iData, mfilename, a, files{i}.Source);
end % for

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),out);
end

% ------------------------------------------------------------------------------
function s=load_check_struct(data, loaders, filename)
% check final structure and add missing fields
  if nargin < 3, filename=''; end
  if isempty(filename), filename=pwd; end
  if iscell(filename),  filename=filename{1}; end
  
  % transfer some standard fields as possible
  if ~isstruct(data)          s.Data = data; else s=data; end
  if isfield(data, 'Source'), s.Source = data.Source; 
  else                        s.Source = filename; end
  if isfield(data, 'Title'),  s.Title = data.Title; 
  else 
    [pathname, filename, ext] = fileparts(filename);
    s.Title  = [ 'File ' filename ext ];
  end
  if isfield(data, 'Date'),   s.Date   = data.Date; 
  else                        s.Date   = clock; end
  if isfield(data, 'Label'),  s.Label = data.Label; end
  if ~isfield(s, 'Format'),
    s.Format  = loaders{1}.name; 
  end

% ------------------------------------------------------------------------------
function this = load_eval_postprocess(this, postprocess)
% evaluate the postprocess in a reduced environment, with only 'this'
  try
    % disp([ mfilename ': Calling post-process '  postprocess ])
    if isvarname(postprocess) && exist(postprocess) == 2
      this = feval(postprocess, this);
    elseif isempty(postprocess == '=')
      this = eval(postprocess);
    else
      eval(postprocess);
    end

    this = setalias(this, 'postprocess', postprocess);
    this = iData_private_history(this, postprocess, this);
  catch
    warning([mfilename ': Error when calling post-process ' postprocess ]);
  end
    
    
