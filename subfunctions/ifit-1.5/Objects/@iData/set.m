function this = set(this,varargin)
% [s,...] = set(s, 'PropertyName', Propertyvalue, ...) : set iData properties
%
%   @iData/set function to set iData properties.
%   set(s, 'PropertyName', Propertyvalue, ...}) 
%     sets values into given property names for the iData object s.
%   set(s, Struct.Field, ...)
%     sets values from given structure fields into the iData object s.
%   set(s, CellNames, CellValues, ...)
%     sets values from given cells into the iData object s.
%   set(s) indicates the signification of the iData base properties
%   The input iData object is updated if no output argument is specified.
%
% ex      : set(iData,'Title','A nice Title')
%
% Version: $Revision: 1158 $
% See also iData, iData/get, iData/setalias, iData/setaxis

% EF 27/07/00 creation
% EF 23/09/07 iData implementation
% ============================================================================
% calls: subsasgn

% calls: setalias

if nargin == 1
  disp('iData object properties:');
  disp('Title:      (string)   title of the Data set');
  disp('Tag:        (string)   unique ID for the Data set');
  disp('Source:     (string)   origin of data (filename/path)');
  disp('Command:    (cellstr)  history of commands applied to object');
  disp('Date:       (string)   data set creation date');
  disp('UserData:   (any type) user data storage area');
  disp('Label:      (string)   user label');
  disp('DisplayName (string)   string displayed in plot legends');
  disp('Creator:    (string)   application that created this data set');
  disp('User:       (string)   user of this Data set');
  disp('Data:       (any type) Data storage area');
  disp('Signal:     (double)   The signal to be used for data set math operations/plotting.');
  disp('Error:      (double)   the error bars on the signal to be used for data set math operations/plotting.');
  disp('Monitor:    (double)   the monitor(statistical weight) on the signal to be used for data set math operations');
  disp('Axis:       list of axis defined for data set math operations/plotting. Use setaxis/getaxis');
  disp('Alias:      list of aliases/links to data items.                        Use setalias/getalias');
  disp('ModificationDate: (string)   last object modification date');
  this = iData(this);
  return
end

% handle array of objects
if numel(this) > 1
  parfor index=1:numel(this)
    this(index) = set(this(index), varargin{:});
  end
  if nargout == 0 && ~isempty(inputname(1)) % update array inplace
    assignin('caller', inputname(1), this);
  end
  return
end

% handle single object
% extract the Property/Value pairs
i1 = 1; % index in input parameters varargin
prop_names = {}; prop_values = {};
index = 1;
while index < length(varargin)    % first parse fields and values
  if ischar(varargin{index})      % normal 'PropertyName', Propertyvalue
    prop_names{end+1}  = varargin{index};         % get single PropertyName
    prop_values{end+1} = varargin{index+1};       % get single PropertyValue
    index = index+2;
  elseif isstruct(varargin{index})         % import structure
    prop_names  = fieldnames(varargin{index});         % get PropertyNames
    prop_values = struct2cell(varargin{index});
    index = index+1;
  elseif iscell(varargin{index}) && index < length(varargin) % import from 2 cells
    prop_names  = varargin{index};        % get PropertyNames
    prop_values = varargin{index+1};      % get PropertyValue
    index = index+2;
  else
    iData_private_error(mfilename, [ 'PropertyName ' num2str(index) ' should be char strings in object ' inputname(1) ' ' this.Tag ' and not ' class(varargin{index}) ]);
  end
end

% now update the Properties
for index=1:length(prop_names) % loop on properties cell
  % test if this is a unique property, or a composed one
  if isvarname(prop_names{index})  % extract iData field/alias
    s    = struct('type', '.', 'subs', prop_names{index});
    this = subsasgn(this, s, prop_values{index});
  else % this is a compound property, such as set(this,'Data.Signal', ...)
  
    eval([ 'this.'  prop_names{index} ' = prop_values{index};' ]);
  end
end

% update the object
if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),this);
end

