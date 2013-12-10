function out = iData(varargin)
% d = iData(a, ...) : iData class object constructor
%
% The iData objects are the containers where to import your data sets. It is then
% possible to Load, Plot, apply Math operators, Fit, and Save.
%
% Creates an iData object which contains data along with additional information.
%   An iData object may store any Data, and define its Signal, Error, Monitor, 
%     and Axes as aliases refering to e.g. parts of the Data.
%   The input argument 'a', is converted into an iData object. It may be:
%     a scalar/vector/matrix
%     a string giving a file name to load. Use alternatively iData/load.
%     a structure
%     a cell array which elements are imported separately
%     a iData object (updated if no output argument is specified).
%   The special syntax iData(x,y, .., c) creates an iData with
%     signal c and axes x,y, ... where these are all numerics with 'x'
%     for the columns (2nd axis rank), 'y' for the rows (1st axis rank), ...
%   The syntax iData(iFunc object) evaluates the iFunc model using the iData
%     object axes, and returns the model value as an iData object.
%   The output argument is a single object or array of iData.
%   Input arguments may be more than one, or given as cells.
%
% When used with file names, compressed files may be used, as well as URLs and internal
%   anchor reference using the '#' character, such as in 'http://path/file.zip#Data'.
%
% Type <a href="matlab:doc(iData)">doc(iData)</a> to access the iFit/iData Documentation.
% Refer to <a href="matlab:doc iData/load">iData/load</a> for more information about loading data sets.
% iData is part of iFit http://ifit.mccode.org 
%
% examples:
%   d=iData('filename'); a=iData('http://filename.zip#Data');
%   d=iData(rand(10));
%
% Version: $Revision: 1165 $
% See also: iData, iData/load, methods, iData/setaxis, iData/setalias, iData/doc

% object definition and converter
% EF 23/09/07 iData implementation
% ============================================================================
% internal functions
%   iData_struct2iData
%   iData_num2iData
%   iData_cell2iData
%   iData_check
%   load_clean_metadata

out = [];

if nargin == 0  % create empty object
  % create a new iData object
  a.Tag          = 0;           % unique ID
  a.Title        = '';          % Data title
  a.Source       = pwd;         % origin of data (filename/path)
  a.Creator      = [];          % Creator (program) name
  user = getenv('USER');
  if isempty(user), user = getenv('HOME'); end
  if isempty(user), user = getenv('TEMP'); end % gives User name on Windows systems
  a.User         = user;        % User ID
  a.Date         = clock;
  a.ModificationDate  = a.Date; % modification Date
  a.Command      = '';          % Matlab commands/history of the object
  a.UserData     = '';          % user data storage area
  a.Label        = '';          % user label (color)
  a.DisplayName  = '';          % user name for handling data set as a variable
  
  % hidden fields
  a.Data         =[];           % Data storage area
  a.Alias.Names  ={ ...
        'Signal','Error','Monitor'}; % (cell) Alias names
                                % special alias: signal
                                % special alias: errors on signal
                                % special alias: monitor (statistical weight)
  a.Alias.Values ={'','',''};   % (cell) Alias values=string pointing to this Data/object or expr
  a.Alias.Labels ={...          % (cell) Alias labels/descriptions
        'Data Signal','Error on Signal','Monitor (weight)'};  
  a.Alias.Axis   ={};           % (cell) ordered list of axes names (Aliases)  

  % create the object
  a=iData_private_newtag(a); 
  a = class(a, 'iData');
  a.Command      = { [ 'iData %% create ' a.Tag ] };
  a.Creator      = version(a);     % Creator (program) name
  out = a;
  return
else  % convert input argument into object
  if isa(varargin{1}, 'iData') && numel(varargin{1}) > 1
  % iData(iData array)
    out = varargin{1};
    parfor index=1:numel(out)
      out(index) = iData(out(index));        % check all elements
    end
    if nargout == 0 && ~isempty(inputname(1))
      assignin('caller',inputname(1),out)
    end
    return
  elseif ~isa(varargin{1}, 'iData') && isnumeric(varargin{1}) && length(varargin) > 1  % array -> iData
    % iData(x,y,..., signal)
    index = length(varargin);
    out   = iData(varargin{index});  % last argument is the Signal
    
    % handle axes
    for k1=1:(index-1)
      % in plotting convention, X=2nd, Y=1st axis
      if     k1 <= 2 && ndims(out) >= 2, k2 = 3-k1; 
      else   k2 = k1; end
      out = set(out,    [ 'Data.Axis_' num2str(k1) ], varargin{k2});
      out = setaxis(out, k1, [ 'Axis_' num2str(k1) ], [ 'Data.Axis_' num2str(k1) ]);
      label(out, k1, inputname(k2));
    end
    % check in case the x,y axes have been reversed for dim>=2, then swap 1:2 axes in Signal
    if ndims(out)>=2 && isvector(getaxis(out, 1)) && isvector(getaxis(out, 2)) ...
                && length(getaxis(out, 1)) == size(get(out,'Signal'),2) ...
                && length(getaxis(out, 2)) == size(get(out,'Signal'),1) ...
                && length(getaxis(out, 1)) ~= length(getaxis(out, 2))
      s=get(out,'Signal'); out = set(out, 'Signal', s'); clear s
      disp([ 'iData: The Signal has been transposed to match the axes orientation in object ' out.Tag ' "' out.Title '".' ]);
    end
    if ~isempty(inputname(index))
        out.Label=[ inputname(index) ' (' class(varargin{index}) ')' ];
        out = label(out, 0, inputname(index));
        out.Title=inputname(index);
    end

    return
  elseif ischar(varargin{1}) % filename -> iData
  % iData('filename', ...)
    out = load(iData, varargin{:});        % load file(s) with additional arguments. Check included.
    return
  elseif isa(varargin{1}, 'iData')
    % iData(iData single)
    out = varargin{1};                     % just makes a check
  elseif isstruct(varargin{1})
    % iData(struct)
    out = iData_struct2iData(varargin{1}); % convert struct to iData
  elseif isscalar(varargin{1}) && ishandle(varargin{1}) && numel(varargin{1})==1 % convert single Handle Graphics Object
    % iData(figure handle)
    out = iData_handle2iData(varargin{1});
    return
  elseif isnumeric(varargin{1})
    % iData(x)
    out = iData_num2iData(varargin{1});    % convert single scalar/vector/matrix to iData
    return
  elseif iscell(varargin{1})
    % iData(cell)
    out = iData_cell2iData(varargin{1});   % convert cell/cellstr to cell(iData)
    return
  elseif isa(varargin{1}, 'iFunc')
    in = varargin{1};
    [signal, ax, name] = feval(in);
    if length(signal) == length(in.Parameters)
      [signal, ax, name] = feval(in, signal);
    end
    out = iData(ax{:}, signal);
    clear signal ax
    out.Alias.Values{2} = 0;
    return
  else
    iData_private_warning(mfilename, [ 'import of ' inputname(1) ' of class ' class(varargin{1}) ' is not supported. Ignore.' ]);
    out = [];
  end
    
  % check the object
  if ~isa(varargin{1}, 'iData')
    if ~isempty(inputname(1)), in_name=[ inputname(1) ' ' ]; else in_name=''; end
    for index=1:numel(out)
      if numel(out) == 1 || ~isempty(out(index))
        if isempty(out(index).Source), out(index).Source = in_name; end
        if isempty(out(index).Title),  out(index).Title  = [ in_name ' (' class(varargin{1}) ')' ]; end
        
        if isempty(out(index).Command)
          out(index) = iData_private_history(out(index), mfilename, varargin{1}); 
        end
      end
    end
  end
  
  out = iData_check(out); % private function
  
  if isa(varargin{1}, 'iData') && nargout == 0 && ~isempty(inputname(1))
    assignin('caller',inputname(1),out);
  end
    
end

return
  
% ============================================================================
% iData_cell2iData: converts a cell into an iData array
function b=iData_cell2iData(a)
  b = [];
  for k=1:numel(a)
    b = [ b iData(a{k}) ];
  end
  try
    b = reshape(b,size(a));
  end

% ============================================================================
% iData_num2iData: converts a numeric into an iData
function b=iData_num2iData(v)
  b=iData;
  b.Data.Signal = v;
  setalias(b,'Signal','Data.Signal');
  if length(size(v)) > 2, v=v(:); end
  if numel(v) > 10, v=v(1:10); end
  v = mat2str(double(v)); 
  b.Command= cellstr([ 'iData(' v ')' ]);
  
% ============================================================================

