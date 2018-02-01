function [varargout] = get(this,varargin)
% [...] = get(s, 'PropertyName', ...) : get iFunc object properties
%
%   @iFunc/get function to get iFunc properties.
%   get(s) displays all property names and their current values for
%     the iFunc object 's'.
%   get(s,'PropertyName',...) returns only particular properties.
%     The PropertyName can be any iFunc object field, or a model parameter name
%       or 'p' to designate the vector of parameter values (when previously set).
%   Input 's' can be a single iFunc or a iFunc array
%
%   A faster syntax for the 'set' method is: s.PropertyName
%
% input:  s: object or array (iFunc)
%         PropertyName: name of Property to search (char)
% output: property: property value in 's' (cell)
% ex :    get(iFunc) or get(iFunc,'Title')
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/set

% EF 27/07/00 creation
% EF 23/09/07 iFunc implementation
% ============================================================================
% calls: subsref (mainly): get is a wrapper to subsref

persistent fields

if isempty(fields), fields=fieldnames(iFunc); end

% handle array of objects
varargout = {};

if numel(this) > 1
  varg = {};
  for index=1:numel(this)
    varg{end+1} = get(this(index), varargin{:});
  end
  varargout{1} = varg;
  return
end

if nargin == 1
  disp(this, inputname(1));
  varargout{1} = display(this, inputname(1));
  return
end

% handle single object
for index=1:length(varargin)
  property = varargin{index}; % get PropertyName
  if isempty(property), continue; end
  if ~ischar(property)
    error([ mfilename ': PropertyName should be char strings in object ' inputname(1) ' ' this.Tag ' "' this.Title '" and not ' class(property) ]);
  end
  % test if this is a unique property, or a composed one
  if isvarname(property)  % extract iFunc field/alias
    if any(strcmp(property, fields))
      b = this.(property);               % direct static field
      if isnumeric(b) && any(strcmp(property, {'Date','ModificationDate'}))
        b = datestr(b);
      end
      varargout{1} = b;
    else
      s = struct('type','.','subs', property);      % MAIN TIME SPENT
      varargout{1} = subsref(this, s);              % calls subsref directly (single subsref level)
    end
  end
end

if isempty(varargout)
  varargout={[]};
end
