function [val, lab] = getaxis(s,ax)
% [val, lab] = getaxis(s, AxisIndex) : get iData axis value and label
% [val, lab] = getaxis(s, 'AxisName|AxisIndex'): get iData axis definition and label
%
%   @iData/getaxis function to get iData axis value, definition and alias.
%   An axis is an alias associated with an index/rank.
%   when the axis input parameter is given as an index (integer), 
%     the value of the axis is returned.
%   when the axis input parameter is given as a string/name (e.g. '1' or 'x') 
%     the corresponding axis definition is returned.
%   The Signal/Monitor corresponds to axis rank 0, and can also be accessed with
%     getaxis(a, 'Signal') and a{0}.
%   The Error/Monitor an also be accessed with getaxis(a, 'Error').
%   Axis 1 is often labelled as 'y' (rows, vertical), 2 as 'x' (columns, horizontal).
%   The special syntax s{0} gets the signal/monitor only (same as double(s)), 
%     and s{n} gets the axis of rank n.
%
% input:  s: object or array (iData)
%         AxisIndex: axis index to inquire in object, 
%           or [] to obtain all axis values 
%           or '' to obtain all axis definitions (integer).
%         AxisName: axis name to inquire in object, or '' (char). The name may
%                   also be specified as 'n' where n is the axis index, e.g. '1'
% output: val: axis value, or corresponding axis name  (double/char)
%         lab: axis label (char)
% ex:     getaxis(iData,1), getaxis(iData,'1'), getaxis(s, 'y')
%
% Version: $Revision: 1158 $
% See also iData, iData/set, iData/get, iData/getalias

% EF 23/09/07 iData implementation
% ============================================================================

if nargin == 1
  ax = '';
end

% handle iData array
if numel(s) > 1
  val = cell(size(s)); lab=val;
  parfor index=1:numel(s)
    [v,l] = getaxis(s(index), ax);
    val{index} =v;
    lab{index} =l;
  end
  return
end

% now we have a single object
val = []; lab=''; link='';

% syntax: getaxis(object) -> returns all axes definitions
if isempty(ax)
  if ischar(ax) % syntax: getaxis(object, '') -> definitions
    val = s.Alias.Axis;
  else          % syntax: getaxis(object, []) -> values
    val = cell(1, length(s.Alias.Axis)); lab=val;
    parfor index=1:length(s.Alias.Axis)
      [val{index}, lab{index}] = getaxis(s, index); % consecutive calls for each axis
    end
  end
  return
end

% syntax: getaxis(object, number) -> return the axis value
if isnumeric(ax) % given as a number, return a number
  if length(ax) > 1
    val = cell(1, length(ax)); lab=val;
    parfor index=1:length(ax)
      [val{index}, lab{index}] = getaxis(s, ax(index));
    end
    return
  end
  ax = ax(1);
  if ax > ndims(s) && ax > length(s.Alias.Axis)
    return
    % iData_private_error(mfilename, [ 'The ' num2str(ax) '-th rank axis request is higher than the iData Signal dimension ' num2str(ndims(s)) ]);
  end
  if ax == 0  % syntax: getaxis(object, 0) -> object.Signal
    val= subsref(s,struct('type','.','subs','Signal'));
    if ~isfloat(val), val=double(val); end
    m  = subsref(s,struct('type','.','subs','Monitor')); 
    if ~isfloat(m), m=double(m); end
    m=real(m);
    link='Signal';
    if not(all(m == 1 | m == 0))
      val = genop(@rdivide,val,m);
    end
  else
    % get the Axis alias
    if ax <= length(s.Alias.Axis)
      if ischar(s.Alias.Axis)
        link = s.Alias.Axis(ax,:);
      elseif iscell(s.Alias.Axis)
        link = s.Alias.Axis{ax};
      end
      % get the axis value. This means the axis link is correctly defined.
      if ~isempty(link)
        try
          val = get(s, link); 
        catch
          val = [];
        end
      end
    end
  end;
else % given as a char/cell, return a char/cell
  if iscell(ax) && ischar(ax{1})
    val = cell(1, length(ax)); lab=val;
    parfor index=1:length(ax)
      [val{index}, lab{index}] = getaxis(s, ax{index});
    end
    return
  end
  if     strcmp(ax,'Signal'), 
    [val, lab] = getaxis(s,0);
    return;
  elseif strcmp(ax,'Error')
    val= subsref(s,struct('type','.','subs','Error'));
    if ~isfloat(val), val=double(val); end
    m  = subsref(s,struct('type','.','subs','Monitor')); 
    if ~isfloat(m), m=double(m); end
    m=real(m);
    link='Error';
    if not(all(m(:) == 1 | m(:) == 0))
      val = genop(@rdivide,val,m);
    end
  else
    axis_str = str2double(ax);
    if isempty(axis_str) || isnan(axis_str) % not a number char
      ax = find(strcmp(ax, s.Alias.Axis));
      if ~isempty(ax), link = s.Alias.Axis{ax}; end
    else
      ax = axis_str;
      if axis_str == 0
        link = 'Signal';
      elseif 0 < ax && ax <= length(s.Alias.Axis)
        if ischar(s.Alias.Axis)
          link = s.Alias.Axis(ax,:);
        elseif iscell(s.Alias.Axis)
          link = s.Alias.Axis{ax};
        end
      else
        val=''; lab=''; return
      end
    end
    val = link;
  end
end

[dummy, lab]  = getalias(s, link);
if isempty(lab), 
  lab=[ link ' axis' ]; 
    if     ax == 1, lab = [ lab ' (y)' ];
    elseif ax == 2, lab = [ lab ' (x)' ]; 
    elseif ax == 3, lab = [ lab ' (z)' ]; 
    elseif ax == 4, lab = [ lab ' (t)' ];end
elseif ischar(lab)
    lab(~isstrprop(lab,'print'))=' ';
end

if isempty(val) & ax
  if length(find(size(s) > 1)) == 1
    val=1:max(size(s));
  else
    val=1:size(s, ax);
  end
  iData_private_warning(mfilename, ...
  [ 'The ' num2str(ax) '-th rank axis has not been defined yet (use setaxis).\n\t' ...
    'Using default value=1:' num2str(length(val)) ' in object ' inputname(1) ' ' s.Tag ' "' s.Title '".'  ]);
  lab = [ 'Axis ' num2str(ax) ];
end

% orient the axis in the right dimension if this is a vector
if ~ischar(val)
  n = size(val);
  if ax > 0 & length(find(n > 1)) == 1
    if length(find(size(s) > 1)) ~= 1
      v = ones(1, length(n));
      v(ax) = max(n);
      if prod(size(val)) == prod(v), val   = reshape(val, v); end
    else
      if prod(size(val)) == prod(size(s)), val = reshape(val, size(s)); end
    end
  end
  if isnumeric(val) && ~isfloat(val)
    val = double(val);
  end
end

