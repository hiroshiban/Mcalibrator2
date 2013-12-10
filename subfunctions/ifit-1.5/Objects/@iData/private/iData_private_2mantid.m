function b = iData_private_2mantid(a)
% private function to convert/clean an object to match a Mantid processed 
% workspace
% once created, the Mantid workspace can be saved with:
%  save(b, '', 'hdf5 data');

% Mantid processed workspace:
% root: [NeXus_version = 4.2.0 ; file_name = ... ; HDF5_Version = 1.6.5 ;
%        file_time = 2010-08-26T09:57:42+01:00]
% mantid_workspace_1: [NX_class = NXentry] group
%   definition: [URL = http://www.nexusformat.org/instruments/xml/NXprocessed.xml;
%              Version = 1.0]
%     char="Mantid Processed Workspace"
%   definition_local: [URL = http://www.isis.rl.ac.uk/xml/IXmantid.xml;
%              Version = 1.0] deprecated
%     char="Mantid Processed Workspace"
%   program_name: [version=char;configuration=char] char="iFit"
%   title: char=<title of the workspace -> name of workspace>
%
%   instrument: [NX_class = NXinstrument] group
%     name: [short_name=char] char=<name of instrument>
%     instrument_parameter_map: [NX_class = NXnote] group
%       data: char=""
%       type: char="text/plain"
%     instrument_source: char=""
%     instrument_xml: [NX_class = NXnote] group
%       data: char=""
%       description: char="XML contents of the instrument IDF file."
%       type: char="text/xml"
%   process: [NX_class = NXprocess] group
%     date: date
%     program: char
%     version: char
%     MantidAlgorithm_XX: [NX_class = NXnote] group
%       author: char
%       data: char
%       description: char
%   workspace: [NX_class = NXdata] group
%     axisN: [axis=N;long_name=label] double ...
%     errors: double
%     values: [signal=1; axes=axis1,axis2...;long_name=label]
%

% root level attributes for HDF/NeXus
[majnum minnum relnum] = H5.get_libversion;

b = copyobj(a);

% set the new object empty
b=rmaxis(b);
b=rmalias(b);
b.Data = [];

% move initial data as 'ifit_workspace'
% b.Data.ifit_workspace = a.Data;

b.Data.Attributes.NeXus_version= '4.2';
b.Data.Attributes.file_name    = a.Source;
b.Data.Attributes.HDF5_Version = sprintf('%i.%i.%i', majnum, minnum, relnum);
b.Data.Attributes.file_time    = datestr(now);

% search for an existing 'mantid_workspace' item -------------------------------
all_fields = findfield(a);
match      = all_fields(~cellfun(@isempty, strfind(all_fields, 'mantid_workspace')));

% copy any existing 'mantid_workspace'
if ~isempty(match)
  if ~any(strcmp(match, 'Data.mantid_workspace_1'))
    [dummy, index] = min(cellfun('length', match));   % field which path length is smallest
    dummy          = get(a, match{index});            % to avoid sub-structure
    if isstruct(dummy)  % must be a 'group' (structure)
      b.Data.mantid_workspace_1 = dummy; 
      clear dummy
    else
      match=[]; % still request creation of group
    end
  else
    b.Data.mantid_workspace_1 = a.Data.mantid_workspace_1;
  end
end

% create NXentry 'mantid_workspace_1' (if does not exist)
if isempty(match)
  b.Data.mantid_workspace_1.Attributes.NX_class='NXentry';

  b.Data.mantid_workspace_1.definition='Mantid Processed Workspace';
  % the following URL is broken... and the Mantid/ISIS one as well
  b.Data.mantid_workspace_1.Attributes.definition.URL='http://www.nexusformat.org/instruments/xml/NXprocessed.xml';
  b.Data.mantid_workspace_1.Attributes.definition.Version= '1.0';
end
% add program_name and title (if does not exist)
if ~isfield(b.Data.mantid_workspace_1, 'program_name')
  b.Data.mantid_workspace_1.program_name=version(iData, 'long');
  b.Data.mantid_workspace_1.Attributes.program_name.configuration='http://ifit.mccode.org';
end
if ~isfield(b.Data.mantid_workspace_1, 'title')
  b.Data.mantid_workspace_1.title = a.Title;
end

% Mantid does not support properly re-import of 'sample' group.
% We remove it
if isfield(b.Data.mantid_workspace_1, 'sample')
  % b.Data.mantid_workspace_1 = rmfield(b.Data.mantid_workspace_1, 'sample');
end

% search for an existing 'instrument' item -------------------------------------
match = all_fields(~cellfun(@isempty, strfind(all_fields, 'instrument')));

% copy any existing 'instrument'
if ~isempty(match)
  if ~any(strcmp(match, 'Data.mantid_workspace_1.instrument'))
    [dummy, index] = min(cellfun('length', match));   % field which path length is smallest
    dummy          = get(a, match{index});            % to avoid sub-structure
    if isstruct(dummy)  % must be a 'group' (structure)
      b.Data.mantid_workspace_1.instrument = dummy; 
      clear dummy
    else
      match=[]; % still request creation of group
    end
  else
    b.Data.mantid_workspace_1.instrument = a.Data.mantid_workspace_1.instrument;
  end
end

% create NXinstrument 'instrument' in 'mantid_workspace_1' (if does not exist)
if isempty(match)
  b.Data.mantid_workspace_1.instrument.name=version(iData);
  b.Data.mantid_workspace_1.instrument.Attributes.NX_class='NXinstrument';
  b.Data.mantid_workspace_1.instrument.Attributes.name.short_name='iFit';
end

% add 'instrument_source' (may use 'component' if found)
% avoid duplicated fields (e.g. instrument_parameter_map, instrument_xml, 
%   instrument_source)
if   ~isfield(b.Data.mantid_workspace_1.instrument, 'instrument_source') ...
  && ~isfield(b.Data.mantid_workspace_1, 'instrument_source')
  % McStas compatibility
  match = all_fields(~cellfun(@isempty, strfind(all_fields, 'component')));
  if ~isempty(match)
    [dummy, index] = min(cellfun('length', match));   % field which path length is smallest
    dummy          = get(a, match{index});            % to avoid sub-structure
    b.Data.mantid_workspace_1.instrument.instrument_source = dummy;
  else
    b.Data.mantid_workspace_1.instrument.instrument_source = a.Source;
  end
end
% in some cases, Mantid puts instrument_parameter_map outside 'instrument' group
match = all_fields(~cellfun(@isempty, strfind(all_fields, 'instrument_parameter_map')));

if ~isempty(match)
  if ~any(strcmp(match, 'Data.mantid_workspace_1.instrument_parameter_map')) ...
  && ~any(strcmp(match, 'Data.mantid_workspace_1.instrument.instrument_parameter_map'))
    [dummy, index] = min(cellfun('length', match));   % field which path length is smallest
    dummy          = get(a, match{index});            % to avoid sub-structure
    if isstruct(dummy)  % must be a 'group' (structure)
      b.Data.mantid_workspace_1.instrument.instrument_parameter_map = dummy; 
      clear dummy
    else
      match=[]; % still request creation of group
    end
  end % else it is already in the workspace copy
end

% add 'instrument_parameter_map' (fake as we can not guess it)
if   ~isfield(b.Data.mantid_workspace_1.instrument, 'instrument_parameter_map') ...
  && ~isfield(b.Data.mantid_workspace_1, 'instrument_parameter_map')
  b.Data.mantid_workspace_1.instrument.instrument_parameter_map.data = '';
  b.Data.mantid_workspace_1.instrument.instrument_parameter_map.type = 'text/plain';
  b.Data.mantid_workspace_1.instrument.instrument_parameter_map.Attributes.NX_class = 'NXnote';
end

% in some cases, Mantid puts instrument_xml outside 'instrument' group
match = all_fields(~cellfun(@isempty, strfind(all_fields, 'instrument_xml')));

if ~isempty(match)
  if ~any(strcmp(match, 'Data.mantid_workspace_1.instrument_xml')) ...
  && ~any(strcmp(match, 'Data.mantid_workspace_1.instrument.instrument_xml'))
    [dummy, index] = min(cellfun('length', match));   % field which path length is smallest
    dummy          = get(a, match{index});            % to avoid sub-structure
    if isstruct(dummy)  % must be a 'group' (structure)
      b.Data.mantid_workspace_1.instrument.instrument_xml = dummy; 
      clear dummy
    else
      match=[]; % still request creation of group
    end
  end % else it is already in the workspace copy
end

% add 'instrument_xml' (fake as we can not guess it)
if   ~isfield(b.Data.mantid_workspace_1.instrument, 'instrument_xml') ...
  && ~isfield(b.Data.mantid_workspace_1, 'instrument_xml')
  b.Data.mantid_workspace_1.instrument.instrument_xml.data = '';
  b.Data.mantid_workspace_1.instrument.instrument_xml.type = 'text/xml';
  b.Data.mantid_workspace_1.instrument.instrument_xml.description = 'XML contents of the instrument IDF file.';
  b.Data.mantid_workspace_1.instrument.instrument_xml.Attributes.NX_class = 'NXnote';
end

% search for an existing 'process' item ----------------------------------------
match = all_fields(~cellfun(@isempty, strfind(all_fields, 'process')));

% copy any existing 'process'
if ~isempty(match) 
  if ~any(strcmp(match, 'Data.mantid_workspace_1.process'))
    [dummy, index] = min(cellfun('length', match));   % get the field which path is smallest
    dummy          = get(a, match{index});            % to avoid sub-structure
    if isstruct(dummy)  % must be a 'group' (structure)
      b.Data.mantid_workspace_1.process = dummy; 
      clear dummy
    else
      match=[]; % still request creation of group
    end
  else
    b.Data.mantid_workspace_1.process = a.Data.mantid_workspace_1.process;
  end
end

% create NXprocess 'process' in 'mantid_workspace_1'
if isempty(match)
  b.Data.mantid_workspace_1.process.date   = datestr(now);
  b.Data.mantid_workspace_1.process.Attributes.NX_class='NXprocess';
  b.Data.mantid_workspace_1.process.program= 'iFit';
  b.Data.mantid_workspace_1.process.version= version(iData, 'long');
end

% add NXnotes 'iFitCommands' with lines of Command history
if ~isfield(b.Data.mantid_workspace_1.process, 'iFitCommands')
  b.Data.mantid_workspace_1.process.iFitCommands = sprintf('%s\n', a.Command{:});
else
  b.Data.mantid_workspace_1.process.iFitCommands = ...
   [ b.Data.mantid_workspace_1.process.iFitCommands 
     sprintf('%s\n', a.Command{:}) ];
end

% create NXdata 'workspace' in 'mantid_workspace_1' ----------------------------
% we overwrite any existing workspace, as only one can exist, and should contain
% the Axes+Signal+Error

% Mantid requires data to be double (64 bits).
b.Data.mantid_workspace_1.workspace = []; % clean previous content if any
b.Data.mantid_workspace_1.workspace.Attributes.NX_class = 'NXdata';
b.Data.mantid_workspace_1.workspace.errors              = double(get(a, 'Error'));

if ndims(a) == 1
  % Mantid requires for 1D workspaces, with the second axis2=constant
  axes_attr = ',axis2';
else
  axes_attr = '';
end
for index=1:ndims(a)
  
  lab = getaxis(a, num2str(index));
  if ~ischar(lab), lab=''; end
  
  % Mantid requires that axis_name be 'axisN'
  axis_name = [ 'axis' num2str(index) ];
  
  if index == 1
    axes_attr = [ axis_name axes_attr ]; % also valid for 1D workspaces
  elseif index == 2
    axes_attr = [ axis_name ',' axes_attr ];
  else
    axes_attr = [ axes_attr ',' axis_name ];
  end
  val = double(getaxis(a, index)); 
  
  b.Data.mantid_workspace_1.workspace.(axis_name) = val;
  if ~isempty(label(a, index))
    lab = [ lab ' ' label(a, index); ];
  end
  if ~isempty(lab)
    b.Data.mantid_workspace_1.workspace.Attributes.(axis_name).long_name = strtrim(lab); 
  end
end
% add a second fake axis when 1D workspace for Mantid
if ndims(a) == 1
  % unfortunately, a vector is always stored a a 1D vector in HDF, but mantid requires
  % two dimensions to associate the second axis (second dimension is 1)
  % so we duplicate the signal and make it a matrix.
  s = double(a); s=s(:);
  b.Data.mantid_workspace_1.workspace.axis2 = [ double(1) double(1) ];
  b.Data.mantid_workspace_1.workspace.values                  = [ s s ]; 
  clear s;
else
  b.Data.mantid_workspace_1.workspace.values                  = double(a);
end

b.Data.mantid_workspace_1.workspace.Attributes.values.signal= int32(1);
b.Data.mantid_workspace_1.workspace.Attributes.values.axes  = axes_attr;
if ~isempty(label(a, 0))
  b.Data.mantid_workspace_1.workspace.Attributes.values.long_name = label(a,0);
  b.Data.mantid_workspace_1.workspace.Attributes.values.units     = label(a,0);
end

