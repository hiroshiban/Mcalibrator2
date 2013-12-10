function labl = label(this, varargin)
% b = label(s, alias, label) : Change iData label for a given alias/axis
%
%   @iData/label function to set/get labels
%     label(s, alias) returns the current label
%     label(s)        returns the object Label
%     label(s, rank, label)   sets the object label
%   The input iData object is updated if no output argument is specified.
%
% input:  s: object or array (iData)
%         alias: name of the alias or index of the axis (char/numeric)
%         label: new label (char/cellstr)
% output: b: object or array (iData)
% ex:     b=label(a,'x','new xlabel'); b=label(a,'x'); b=label(a, 1,'new xlabel');
%
% Version: $Revision: 1158 $
% See also iData, iData/plot, iData/xlabel, iData/ylabel, iData/zlabel, iDala/clabel

if numel(this) > 1
  if nargin < 3
    labl=cell(size(this));
    parfor index=1:numel(this)
      labl{index} = label(this(index), varargin{:});
    end
  else
    parfor index=1:numel(this)
      this(index) = label(this(index), varargin{:});
    end
    labl=this;
    if nargout == 0 & isa(this,'iData') & ~isempty(inputname(1))
      assignin('caller',inputname(1),this);
    end
  end
  
  return
end

% handle different call syntax
if nargin == 1
  % label(a) -> get object Label property
  labl = this.Label;
  return
end

% search for the axis/alias: should get an index value in the aliases/axes
if nargin >= 2
  index = varargin{1};
end
if iscell(index) && ischar(index{1})
  index = index{1};
end
if ischar(index) && ~isnan(str2double(index))
  % label(a, '1', ...) -> label(a, 1)
  index = str2double(index);  % now numeric axis index
end
if isscalar(index) && isnumeric(index)
  if index == 0
    index = 'Signal';
  elseif 0 < index && index <= ndims(this)
    % find the Alias which corresponds with this axis index
    if index <= length(this.Alias.Axis)
      axis_alias = this.Alias.Axis{index};
      if ischar(axis_alias)
        index = axis_alias;
      else
        index = []; % axis content is numeric (not an alias link)
      end
    else
      % the Axis does not exist yet, but object dimensionality allows it
      % we create the axis
      x    = getaxis(this, index);
      this = setaxis(this, index, x);
      index= getaxis(this, num2str(index)); % the Alias for the Axis 'index'
    end
  end
end

if ischar(index)  
   % is this an Alias ?
  isalias = strcmp(index, this.Alias.Names);
  if any(isalias)
    index = find(isalias, 1);
  end
end

% check that rank exists in Alias list
if isempty(index) || ~isnumeric(index) || index > length(this.Alias.Names) || index < 1
    % did not find the alias...
    if nargin == 2
        labl = '';
    else
        labl = this;
    end
    return; 
end

if nargin == 3
  % label(a, rank, lab) -> set Label of the rank/alias
  this.Alias.Labels{index} = varargin{2};
  this = iData_private_history(this, mfilename, this, index, varargin{2});
  if nargout == 0 && ~isempty(inputname(1))
    assignin('caller',inputname(1),this);
  end
  labl = this; % return value
else % nargin == 2
  % label(a, rank) -> get the label value
  labl = this.Alias.Labels{index};
end
