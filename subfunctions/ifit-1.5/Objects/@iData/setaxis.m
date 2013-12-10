function this = setaxis(this, rank, alias, value)
% s = setaxis(s, rank, alias, value) : set iData axes
%
%   @iData/setaxis function to set iData axes.
%     setaxis(object, rank, alias) defines axis of specified rank as the alias.
%       The alias name must exist in the object.
%     setaxis(object, rank, alias, value) also sets the alias value.
%       The alias name must exist in the object, or it is created and assigned to the axis value.
%     setaxis(object, rank, value) sets axis value (possibly creates an alias).
%     setaxis(object)              tests all axes
%     setaxis(object,'Signal')     sets the Signal to the biggest numerical field
%   The input iData object is updated if no output argument is specified.
%   The Signal/Monitor corresponds to axis rank 0. Setting its value multiplies 
%     it by the Monitor and then assigns the Signal.
%   Axis 1 is often labelled as 'y' (rows, vertical), 2 as 'x' (columns, horizontal).
%   The special syntax a{0} multiplies the value by the Monitor and then assigns 
%   the Signal, and a{n} assigns the axis of rank n.
%     When the assigned value is a char, the axis definition is set.
%       a{rank} = 'x'     is the same as   setaxis(a, rank, 'x')
%     When the assigned value is numeric, the axis value is set.
%       a{rank} = 1:100   is the same as   setaxis(a, rank, 1:100)
%
% input:  s: object or array (iData)
%         rank: rank of the axis (integer)
%         alias: name of an alias/field (char)
%         value: value of the axis (char/alias/numeric)
% output: s: array (iData)
% ex:     setaxis(iData, 1, 'Temperature') defines Temperature as the 'y' axis (rank 1)
%         a{1} =  'Temperature'            does the same
%
% Version: $Revision: 1035 $
% See also iData, iData/getaxis, iData/get, iData/set, iData/rmaxis

% EF 27/07/00 creation
% EF 23/09/07 iData implementation
% ==============================================================================

persistent fields

if isempty(fields), fields=fieldnames(iData); end

if nargin < 3
  alias='';
end
if nargin < 4
  value=[];
end

% handle array of objects
if numel(this) > 1
  parfor index=1:numel(this)
    if nargin == 1
      this(index) = iData_checkaxes(this(index));
    elseif nargin == 3
      this(index) = setaxis(this(index), rank, alias);
    elseif nargin == 4
      this(index) = setaxis(this(index), rank, alias, value);
    end
  end
  if nargout == 0 && ~isempty(inputname(1)) % update array inplace
    assignin('caller', inputname(1), this);
  end
  return
end

%     setaxis(object)              tests all axes
if nargin == 1
  this = iData_checkaxes(this);
  if nargout == 0 & length(inputname(1))
    assignin('caller',inputname(1),this);
  end
  return
end

% check input arguments
if strcmp(rank, 'Signal'), rank=0; end
if isempty(rank) && isempty(alias), return; end
if ~isnumeric(rank), 
  iData_private_error(mfilename,[ 'the axis rank should be numeric and not ' class(rank) '.' ]);
end
if isnumeric(alias), value = alias; alias = ''; end

if ischar(rank)
  rank = str2double(rank);
end

% handle arrays of ranks/alias
if isempty(isnan(rank)) && numel(rank) > 1
  for index=1:numel(rank)
    this = setaxis(this, rank(index), alias, value);
  end
  return
elseif iscell(alias)
  for index=1:numel(alias)
    this = setaxis(this, rank, alias{index}, value);
  end
  if nargout == 0 & length(inputname(1))
    assignin('caller',inputname(1),this);
  end
  return
end

% get the rank from the axis definition (alias) 
if isempty(rank) && ~isempty(alias)
  rank = find(strcmp(alias, this.Alias.Axis));

% get the axis definition from the rank, or uses default alias for the axis 
elseif ~isempty(rank) && isempty(alias)
  % get the Axis definition
  if rank == 0
    if isempty(alias) || isempty(value) % reset Signal (find biggest field)
      this = setalias(this, 'Signal',[]);
      if nargout == 0 & length(inputname(1))
        assignin('caller',inputname(1),this);
      end
      return
    end
    alias = 'Signal';
    if nargin == 4 % adapt value to Monitor
      m  = get(this, 'Monitor'); m=real(m);
      if not(all(m(:) == 1 | m(:) == 0))
        value = genop(@times, value , m);
      end
    end
  elseif rank <= length(this.Alias.Axis)
    alias = this.Alias.Axis{rank};
  end
  if isempty(alias) && ~isempty(value)
    % the alias 'Axis_<rank>' sould be used
    alias = [ 'Axis_' num2str(rank) ];
  end
end

if isempty(rank) || isempty(alias), return; end

% check if the alias already exists in the object
if strcmpi(alias, fields) % this is a protected field of the object
  iData_private_error(mfilename,[ 'the Alias ' alias ' is a protected name in object ' ...
    inputname(1) ' ' this.Tag ' "' this.Title '".' ]);
end

if isempty(find(strcmpi(alias, this.Alias.Names))) % the alias does not exist yet
  if isempty(value)
    % perhaps the value refers to an existing field in the object: create a
    % new Alias
    try
      val = get(this, alias);
      setalias(this, [ 'Axis_' num2str(rank) ], alias);
      alias = [ 'Axis_' num2str(rank) ];
    end
  end
end
% try again
if isempty(find(strcmpi(alias, this.Alias.Names)))
  if isempty(value)
    iData_private_warning(mfilename,[ 'the Alias ' alias ' used to define axis rank ' ...
      num2str(rank) ' does not exist in object ' inputname(1) ' ' this.Tag ' "' this.Title '".' ]);
    return;
  else
    iData_private_warning(mfilename,[ 'the Alias ' alias ' used to define axis rank ' ...
      num2str(rank) ' does not exist in object ' inputname(1) ' ' this.Tag ' "' this.Title '".\n\tDefining it.' ]);
  end
end

% assign the alias
if rank == 0
  if ~strcmp(alias, 'Signal')
    setalias(this, 'Signal', alias);
  end
else
  this.Alias.Axis{rank} = alias;
end

% assign the value to the alias
if ~isempty(value)
  setalias(this, alias, value);
end

this = iData_private_history(this, mfilename, this, rank, alias, value);

% update output
if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),this);
end

% ==============================================================================
% private function iData_checkaxes
function this = iData_checkaxes(this)

% makes a check of axes and Signal, notice invalid ones, move unused singleton to end.
  axis_1D=[];
  size_this=size(this);
  for index=1:length(this.Alias.Axis) % scan axis definitions and values
    link = this.Alias.Axis{index};
    if length(size_this) < index, size_this(index)=1; end
    try
      val  = get(this, link);
      if numel(val) == 1 % these are to be moved after the other axes
        axis_1D= [ axis_1D index ];
      end
      % the axis value is valid, but does not have the right dimension
      % test: val is a vector and matches the length of numel(Signal)
      % OR numel(val) == numel(Signal)
      if ( numel(val) ~= prod(size_this) )
        iData_private_warning(mfilename, [ 'the Axis ' link ' ' num2str(index) ...
          '-th rank length [' num2str(size(val)) '] does not match the Signal dimension [' ...
          num2str(size_this) '] in object ' inputname(1) ' ' this.Tag '.' ]);
      end
    catch
      % the axis value is invalid.
      
      iData_private_warning(mfilename,[ 'the Axis ' link ' ' num2str(index) ...
        '-th rank is not valid in object ' inputname(1) ' '  this.Tag ' "' this.Title '".' ]);
    end
  end % for index
  
  % remove singleton axes and put them in end position
  ax = this.Alias.Axis;
  if ~isempty(axis_1D) && length(axis_1D) < length(ax) 
    for index=length(axis_1D):-1:1
      if axis_1D(index) > 0
        tmp = ax{axis_1D(index)};
        ax(axis_1D(index)) = [];
        ax{end+1} = tmp;
      end
    end
    this.Alias.Axis = ax;
  end
  
