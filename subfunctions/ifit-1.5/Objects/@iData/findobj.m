function [varargout] = findobj(s_in, varargin)
% [s,...]=findobj(s,...) : look for existing iData objects
%
%   @iData/findobj function to look for existing iData objects
%
%   [caller, base] = findobj(iData) returns the names of all iData objects 
%     in base workspace and caller workspace into cells.
%   [caller, base] = findobj(iData,'Property','Value')
%   [caller, base] = findobj(s,'Property','Value') 
%     Returns the iData objects (in s or workspaces)
%     that match the required properties.
%
% input:  s: object or array (iData)  (iData)
%         PropertyName: name of Property to search (char)
%         PropertyValue: value of PropertyName to search (char), in pairs with PropertyName
% output: caller: objects found in caller workspace (iData array)
%         base:  objects found in base/MATLAB workspace (iData array)
% ex :    findobj(iData) or findobj(iData,'Title','MyTitle')
%
% Version: $Revision: 1057 $
% See also iData, iData/set, iData/get, iData/findstr, iData/findfield

% EF 23/09/07 iData implementation

% extract iData objects from caller
s_caller = {};
s_base = {};
caller_data = {};
res_caller  = {};
base_data   = {};

vars = evalin('caller','whos');
vars_name  = {vars.name};
vars_class = {vars.class};
iData_i = find(strcmp(vars_class,'iData'));
caller_data = vars_name(iData_i);
% handle cells of iData objects in caller
for i = find(strcmp(vars_class,'cell'))
  rc = evalin('caller',vars_name{i});
  for j = find(cellfun('isclass',rc,'iData'))
    if ~isempty(j), caller_data = [ caller_data, { [vars_name{i} '{' num2str(j(1)) '}'] } ]; end
  end
end

% extract iData objects from base MATLAB
% this evalin call and following block is to be removed for stand-alone application making
if ~exist('isdeployed'), isdeployed=0; end  % set to 1 when using Matlab compiler (mcc)
try
  if ~isdeployed, end
catch
  isdeployed=0;
end
try
  vars = evalin('base','whos');
  vars_name  = {vars.name};
  vars_class = {vars.class};
  iData_i = find(strcmp(vars_class,'iData'));
  base_data = vars_name(iData_i);
  % handle cells of iData objects in Matlab base workspace
  for i = find(strcmp(vars_class,'cell'))
    rb = evalin('base',vars_name{i});
    for j = find(cellfun('isclass',rb,'iData'))
      if ~isempty(j), base_data = [ base_data, { [vars_name{i} '{' num2str(j(1)) '}'] } ]; end
    end
  end
end

if numel(s_in) == 1     % only one iData passed: we use caller/base objects
  for j=1:length(caller_data)
    s_caller{j} = evalin('caller',caller_data{j});
  end
  if ~isdeployed
    for j=1:length(base_data)
      s_base{j} = evalin('base',base_data{j});
    end
  end
else    % work with s_in
  s_caller = s_in;
end

if length(s_caller) == 1
  s_caller=s_caller{1};
end
if length(s_base) == 1
  s_base=s_base{1};
end

if nargin == 1  % and this is a iData
  varargout{1} = s_caller;
  varargout{2} = s_base;
  return
end

% now look for Properties in s
i1 = [];
i2 = i1;
for i = 1:2:length(varargin)
  propname = varargin{i};
  if ~ischar(propname)
    iData_private_error(mfilename, ['Property names must be of type char (currently ' class(propname) ').' ]);
  end
  try
    propvalue = varargin{i+1};
  catch
    propvalue = [];
  end
  index1 = findprop(s_caller, propname, propvalue);
  index2 = findprop(s_base,   propname, propvalue);
  % do an AND operation on the properties
  i1 = [ i1 index1 ];
  i2 = [ i2 index2 ];
end
i1 = unique(i1);
i2 = unique(i2);

if numel(s_caller), s_caller = s_caller(i1(i1 > 0)); end
if numel(s_base),   s_base   = s_base(i2(i2 > 0));   end

varargout{1} = s_caller;
varargout{2} = s_base;



% ==============================================================================
% inline function

function [index, propvalues]=findprop(array, propname, propvalue)
% find a property in an array and return index in array
  propvalues = {};
  index      = [];
  if isempty(array), return; end
  if iscell(array)
    for j = 1:numel(array)
      propvalues{j} = get(array{j},propname);
    end
  else
    propvalues = get(array,propname);
  end

  if isempty(propvalue), return; end
  if ~iscell(propvalue) && ~ischar(propvalue), propvalue={ propvalue }; end
  for j = 1:numel(array)
    prop = propvalues{j}; % property value for iData 'j' in caller workspace
    if iscell(prop)
      prop = prop(:);
      for k = 1:length(prop)
        propk = prop{k};
        if ischar(propvalue)
          index(j) = ~isempty(strfind(propvalue, propk));
        else
          for l=1:length(propvalue)
            this_prop=propvalue{l};
            lpropk = min(length(propk), length(this_prop));
            if all(propk(1:lpropk) == this_prop(1:lpropk)) % compares numeric arrays
              index = [ index j ];
            end
          end
        end
      end
    else
      if ischar(propvalue)
        if ~isempty(strfind(prop, propvalue))
          index = [ index j ];
        end
      else
        for l=1:length(propvalue)
          this_prop=propvalue{l};
          lpropk = min(length(prop), length(this_prop));
          if all(prop(1:lpropk) == this_prop(1:lpropk)) % compares numeric arrays
            index = [ index j ];
          end
        end
      end
    end % iscell
  end % for j

