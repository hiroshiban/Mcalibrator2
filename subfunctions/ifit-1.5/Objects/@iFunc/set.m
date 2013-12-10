function this = set(this,varargin)
% [s,...] = set(s, 'PropertyName', Propertyvalue, ...) : set iFunc properties
%
%   @iFunc/set function to set iFunc properties.
%   set(s, 'PropertyName', Propertyvalue, ...}) 
%     sets values into given property names for the iFunc object s.
%     The PropertyName can be any iFunc object field, or a model parameter name
%       or 'p' to designate the vector of parameter values.
%   set(s, 'Struct.Field', ...)
%     sets values from given structure fields into the iFunc object s.
%   set(s, CellNames, CellValues, ...)
%     sets values from given cells into the iFunc object s.
%   set(s) indicates the signification of the iFunc base properties
%   The input iFunc object is updated if no output argument is specified.
%
%   A faster syntax for the 'set' method is: s.PropertyName = PropertyValue
%   To set a constraint on a model parameter, use:
%     s.parameter='fix'     % to lock its value during a fit process
%     s.parameter='clear'   % to unlock value during a fit process
%     s.parameter=[min max] % to bound value
%     s.parameter=[nan nan] % to remove bound constraint
%     s.parameter=''        % to remove all constraints on 'parameter'
%     s.Constraint=''       % to remove all constraints
%
%   When the Property is a model parameter name 
%
% ex      : set(iFunc,'Title','A nice Title')
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/get, iFunc/setalias, iFunc/setaxis

% EF 27/07/00 creation
% EF 23/09/07 iFunc implementation
% ============================================================================
% calls: subsasgn

% calls: setalias

if nargin == 1
  disp('iFunc object properties:');
  disp('Name:            (string)         name of the iFunc model');
  disp('Tag:             (string)         unique ID for the model');
  disp('Date:            (string)         model creation date');
  disp('UserData:        (any type)       user data storage area');
  disp('Description:     (string)         model description');
  disp('Expression:      (string/cellstr) model expression using parameter ''p'' and axes x,y,z,t,... Should return ''signal''');
  disp('Dimension:       (value)          model dimensionality');
  disp('Constraint:      (string/cellstr) model constraint to evaluate before the Expression');
  disp('Parameters:      (string/cellstr) model parameters');
  disp('ParameterValues: (double)         model parameter values');
  this = iFunc(this);
  return
end

% handle array of objects
if numel(this) > 1
  for index=1:numel(this)
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
  elseif iscellstr(varargin{index}) && index < length(varargin) % import from 2 cells
    prop_names  = varargin{index};        % get PropertyNames
    prop_values = varargin{index+1};      % get PropertyValue
    index = index+2;
  else
    error([ mfilename ': PropertyName ' num2str(index) ' should be char strings in object ' inputname(1) ' ' this.Tag ' and not ' class(varargin{index}) ]);
  end
end

% now update the Properties
for index=1:length(prop_names) % loop on properties cell
  % test if this is a unique property, or a composed one
  if isvarname(prop_names{index})  % extract iFunc field/alias
    s    = struct('type', '.', 'subs', prop_names{index});
    this = subsasgn(this, s, prop_values{index});
  end
end

% update the object
if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),this);
end

