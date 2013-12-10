function out = load_NeXus(in)
% format an HDF file with NeXus structure (signal, axes, ...)
%
% input:
%   in:  initial single HDF/NeXus data set loaded as a raw iData
% returns:
%   out: NXdata and NXdetector blocks
%
% called by: openhdf

% first we identify the number of NXdata and NXdetector blocks

[allfields, alltypes] = findfield(in);

f       = allfields(strcmp(alltypes, 'char'));  % get all char paths
c       = get(in, f);                 % get their content
nxblock = strcmpi(c, 'NXdata') | strcmpi(c, 'NXdetector');
field   = f(nxblock);
if isempty(strfind(in.Format, 'NeXus'))
  in = set(in, 'Format', [ in.Format '/NeXus' ], '');
end

% find other blocks: NXinstrument, NXsample, NXprocess and create aliases
for token={ 'instrument', 'sample', 'process'}
  nxblock = strcmpi(c, [ 'NX' token{1} ]);
  this_path = f(nxblock); 
  % remove Attribute stuff
  if ~isempty(this_path)
    this_path=this_path{1};
    index    =strfind(this_path,'.Attributes');
    if ~isempty(index), this_path= this_path(1:(index-1)); end
    if ~isempty(this_path) && ~isfield(in, token{1}) && ~isfield(in, [ 'NX' token{1} ])
      in = setalias(in, token{1}, this_path, [ 'NX' token{1} ] );
    end
  end
end

out = [];
for index=1:numel(field)
  % create an iData object with the proper Signal, Axes, ...
  if isempty(out)
    this = load_NeXus_NXdata(in, field{index}, 'overload', allfields);
  else
    this = load_NeXus_NXdata(in, field{index}, '',         allfields);
  end
  if isequal(in, this)
    break
  end
end
if length(out) == 0
  out = in;
end

% ------------------------------------------------------------------------------

function nxdata = load_NeXus_NXdata(in, field, overload, findfield_all)
% load_NeXus_NXdata: extract single NXdata block from 'in', which path is given as 'base'
%
% input:
%   in:    iData single object 
%   field:  path in the object structure pointing to an NXdata
%   overload: when present, the returned object is a full copy of the input one
%           else it only contains the NXdata
% output:
%   nxdata: the NXdata block as a structure

if nargin < 3
  overload = '';
end
if nargin < 4
  findfield_all   = findfield(in);
end

% check that base name points to a structure, else move one level up (remove last word)
[base, group, lastword] = load_pathparts(field);
for f={ field, [ base group ], base }
  this_field = f{1};
  % remove any separator at the end
  if this_field(end) == '.' || this_field(end) == '/', this_field(end) = ''; end
  if isstruct(get(in, this_field))
    field = this_field;
    break
  end
end

field_org = field;

% clean the field name with any Attribute token
field = strrep(field, '.Attributes', '');

% isolate the 'field' structure from the initial object, and store it as 'Data'
% in a new object.
if isempty(overload)
  nxdata      = copyobj(in);
  nxdata.Data = []; % will only hold the NXdata
else
  nxdata      = in;     % will update the input object
end

% get the whole iData structure

if ~iscell(findfield_all), findfield_all = { findfield_all }; end
% get the list of fields in the NXdata block
findfield_out   = findfield_all(strncmpi(findfield_all, field, length(field)));

% isolate Attributes paths
Attributes_path = findfield_out(~cellfun(@isempty, strfind(findfield_out, 'Attributes')));
if isempty(Attributes_path)
  % the Attributes may be stored somewhere else, e.g. Data.Attributes.<NXentry>...
  Attributes_path = findfield_all(strncmpi(findfield_all, field_org, length(field_org)));
end

% isolate 'signal' Attributes (end with .signal)
signal_path     = Attributes_path(~cellfun(@isempty, regexp(Attributes_path, '\.(signal)$')));

if isempty(signal_path)
  nxdata = [];
  return  % no 'signal' Attribute found, return
end

% scan all structure members in NXdata and extract their values, to remove any 'link'
for f=findfield_out'        % get this NXdata members in the initial object
  % f{1} is Data...<NXdata>.<member in NXdata>
  val = get(in, f{1});
  if strncmp(fliplr(f{1}), fliplr('.PARAMETERS'), length('.PARAMETERS')) && ischar(val)
    % this is a PARAMETERS from LAMP
    val = str2struct(val);
  end
  nxdata = set(nxdata, f{1}, val);  % make sure we resolve links
  clear val;
end

% get a list of all 'signal' attributes (there should be only one)
for index=1:numel(signal_path)
  % get 'signal' attribute value
  signal_attribute = get(in, signal_path{index});
  if ischar(signal_attribute), signal_attribute = str2double(signal_attribute); end
  % until we find 'signal=1
  if signal_attribute == 1 % when we find the signal, we set the path to a string
    signal_path = signal_path{index};
    break
  end
end

% if Attributes_path is still a cell, then signal was not found as 1, exit
if ~ischar(signal_path)
  % the NXdata block does not hold any signal, we let the automatic Signal/Axes setting
  nxdata = iData(nxdata); % check
  return  
end

% associate 'signal=1' field to 'Signal' Property
signal_path = strrep(signal_path, '.Attributes','');
signal_path = strrep(signal_path, '.signal','');
nxdata      = setalias(nxdata, 'Signal', signal_path);
% set the Signal label from Attributes
Attributes  = fileattrib(nxdata, 'Signal', findfield_all);
% get the file parts to the signal
[base, group, lastword]  = load_pathparts(signal_path);
% is there an 'error' data set in the group ?
index = findfield_out(strcmp(findfield_out, [ base group 'errors' ]));
if ~isempty(index)
  nxdata = set(nxdata, 'Error', index{1});
end

Axes       = {}; % will hold the path to axes (potential candidates)
Axes_ranks = {};

% handle signal Attributes
if isstruct(Attributes)
  % Signal label from Attribues.long_name, units, ...
  lab = '';
  if isfield(Attributes, 'long_name')
    lab = [ lab Attributes.long_name];
  end
  if isfield(Attributes, 'unit_label')
    lab = [ lab Attributes.unit_label ];
  end
  if isfield(Attributes, 'units') && ~isempty(Attributes.units)
    lab = [ lab '[' Attributes.units ']'];
  end
  lab = strtrim(lab);
  if ~isempty(lab), nxdata = label(nxdata, 'Signal', lab); end

  % add axes if present in Attributes
  if isfield(Attributes, 'axes')
    Axes = textscan(Attributes.axes, '%s', 'Delimiter',','); 
    Axes = strcat( [ base group], Axes{1}' ); % the full path to axes
    Axes_ranks = num2cell(1:numel(Axes));
  end
  % assign Errors if present
  if isfield(Attributes, 'uncertainties') && ~isempty(Attributes.uncertainties)
    % set the path to Error as "signal_path"+"uncertainties"
    nxdata = set(nxdata, 'Error', [ base group Attributes.uncertainties ]);
  end
end

% isolate 'axis' Attributes (ends with .axis)
Axis            = Attributes_path(~cellfun(@isempty, regexp(Attributes_path, '\.(axis)$')));
% get the values for the 'axis'
if ~isempty(Axis)
  Axis_ranks = get(in, Axis);
  % make sure we have a cell with values in the end
  if ~iscell(Axis_ranks), Axis_ranks = { Axis_ranks }; end
  % we put 0 when rank is not known, will guess from dimensions
  Axis_ranks(cellfun(@isempty, Axis_ranks)) = { 0 }; 
  % convert e.g. string arguments into double, and keep others
  index = ~cellfun(@isnumeric, Axis_ranks); % non numeric elements
  Axis_ranks(index) =  cellfun(@str2double, Axis_ranks(index), 'UniformOutput',false);
  % add them to the potential Axes list
  Axes       = [ Axes(:)       ; Axis(:) ];
  Axes_ranks = [ Axes_ranks ; Axis_ranks ];
  clear Axis Axis_ranks
end

% scan all axes
% get dimension of Signal
sz = size(nxdata);

% remove unwanted Attributes
for index=1:numel(Axes)
  Axes{index} = regexprep(Axes{index}, '\.Attributes|axes|axis\>', '');
end

Axes_ranks = cell2mat(Axes_ranks);

for index=1:numel(Axes)
  ax = Axes{index};
  % clean Attributes and axis/axes
  % get size of axis
  try
    val = get(nxdata, ax);
  catch
    % the axis does not exist
    if Axes_ranks(index) == 1 && numel(Axes_ranks) > 1 && Axes_ranks(index+1) == 2
      Axes_ranks(index+1) = 1;
    end
    continue;
  end
  sa  = size(val);
  % skip empty and scalar axes
  if all(sa <= 1), continue; end
  % guess rank when not know
  if max(sa) == prod(sa) % axis is a vector
    sa = sa(sa > 1);
  end
  if Axes_ranks(index) == 0 && length(sa) == 1
    Axes_ranks(index) = find(sz == sa); % we guess rank from dimension
  end

  % skip axes which do not match signal
  if ~isempty(Axes_ranks(index)) && Axes_ranks(index) > 0
    % perhaps the axes from Attributes are swapped wrt Signal dimensions
    % but check only the first time
    axes_12 = find(Axes_ranks == 1 | Axes_ranks == 2);
    if index == 1 && length(axes_12) == 2
        ax1 = Axes{axes_12(1)}; val1 = get(nxdata, ax1);
        ax2 = Axes{axes_12(2)}; val2 = get(nxdata, ax2);
        if isvector(val1) && isvector(val2) ...
                && (sz(axes_12(1)) == numel(val2) || sz(axes_12(1)) == numel(val2)-1)
            Axes_ranks(axes_12) = Axes_ranks(fliplr(axes_12));
        end
    elseif index == 1 && numel(Axes) == 1
      Axes_ranks(index) = 1;
    end
    % get the Axis label from Attribues.long_name, units, ...
    Attributes  = fileattrib(nxdata, Axes{index}, findfield_all);
    lab = '';
    if isfield(Attributes, 'long_name')
      lab = [ lab Attributes.long_name];
    end
    if isfield(Attributes, 'unit_label')
      lab = [ lab Attributes.unit_label ];
    end
    if isfield(Attributes, 'units') && ~isempty(Attributes.units)
      lab = [ lab '[' Attributes.units ']'];
    end
    
    % the axis may have n+1 bins (outer bounds per bin)
    if length(sa) == 1 && any(sz == sa-1)
      val = get(nxdata, ax);
      val = (val(1:(end-1)) + val(2:end))/2;
      jj = find(ax == '.', 1, 'last');
      if ~isempty(jj)
        ax = ax((jj+1):end);
      end
      % the new axis should not be the same as the auto-guessed one
      v1 = getaxis(nxdata, Axes_ranks(index));
      if ~isequal(v1(:), val(:))
        nxdata = setalias(nxdata, ax, val); % create a new alias/axis
        nxdata = setaxis(nxdata, Axes_ranks(index), ax);
      end
      if ~isempty(lab), nxdata = label(nxdata, Axes_ranks(index), lab); end
    % check if axis dimension matches the signal rank
    elseif (length(sa) == 1 && sz(Axes_ranks(index)) == sa) ...
            || (length(sz) == length(sa) && all(sz == sa))
      % assign this axis with rank in object, when not equal to the auto-guessed one
      if ~strcmp(getalias(nxdata,getaxis(nxdata, num2str(Axes_ranks(index)))), ax)
        nxdata = setaxis(nxdata, Axes_ranks(index), ax);
      end
      if ~isempty(lab), nxdata = label(nxdata, Axes_ranks(index), lab); end
    else
      fprintf(1,['%s: Warning: NXdata axis %s with dimension %s\n' ...
                  '  does not match signal %s dimension %s for rank %i. Skipping.\n'], ...
        mfilename, ax, mat2str(sa), signal_path, mat2str(sz), Axes_ranks(index));
    end
  end
end

% create short-cuts to some Mantid groups (from the initial object)
if nargin >= 3
  for token={ 'instrument', 'logs', 'process', 'sample' }
    this_path = findfield_all(~cellfun(@isempty, regexp(findfield_all, [ '\.(' token{1} ')$' ])));
    if ~isempty(this_path) && ~isfield(nxdata, token{1}) && ischar(this_path{1})
      nxdata = setalias(nxdata, token{1}, this_path{1});
    end
  end
end

% get title and label
title_path = findfield_all(~cellfun(@isempty, regexp(findfield_all, '\.(title)$')));
if ~isempty(title_path)
  this = get(in, title_path{1});
  if ischar(this), nxdata.Title = this; end
end
expid_path   = findfield_all(~cellfun(@isempty, regexp(findfield_all, '\.(experiment_identifier)$')));
if ~isempty(expid_path)
  expid_path = get(in, expid_path{1});
  if isstruct(expid_path)
    if isfield(expid_path, 'value'), expid_path = expid_path.value; end
  end
  if ischar(expid_path)
    nxdata.DisplayName = strtrim([ nxdata.DisplayName ' ' expid_path  ]);
  end
end
nxdata.Label = [ group lastword ];

% ------------------------------------------------------------------------------
function [base, group, lastword] = load_pathparts(field)
% function to split the entry name into basename, group and dataset
%   field = base.group.lastword
%
% duplicated from iData_getAttribute

  % get group and field names
  lastword_index = find(field == '.' | field == '/', 2, 'last'); % get the group and the field name
  if isempty(lastword_index)
    lastword = field; 
    group    = '';
    base     = '';                            % Attributes.<field>.
  elseif isscalar(lastword_index)
    lastword = field((lastword_index+1):end); 
    group    = field(1:lastword_index);
    base     = '';                            % <group>.Attributes.<field>
  else 
    lastword = field( (lastword_index(2)+1):end ); 
    group    = field( (lastword_index(1)+1):lastword_index(2) ); 
    base     = field(1:lastword_index(1));    % <basename>.<group>.Attributes.<field>
  end


