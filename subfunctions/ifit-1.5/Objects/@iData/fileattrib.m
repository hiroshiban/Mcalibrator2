function [b, link] = fileattrib(a, field, allfields)
% [attribute, link] = fileattrib(s, field) : return a field Attribute
%
%   @iData/fileattrib function which looks for an associated Attribute to a field.
%      Attributes are set from e.g. NetCDF/CDF/NeXus/HDF files.
%      returns []  when no attribute exists
%      returns NaN when the field is already an attribute
%
%   s=fileattrib(s, field, attributes) sets the attribute for given field and return
%     the updated object.
%
% input:  s:     object or array (iData)
%         field: Alias/path in the object (string)
%         attributes: when given as a structure, sets the attributes for the field.
%                     when given as a cellstr, it is used for a faster search of
%                       attributes, e.g. attributes=fieldfield(a)
% output: attribute: the value of the associated Attribute, or [].
%                    or the updated object when storing attributes.
%         link:      the path of the associated Attribute, or [].
% ex:     b=fileattrib(a, 'Signal'); 
%         b=fileattrib(b, 'Signal',struct('long_name','hello world'))
%
% Version: $Revision: 1158 $
% See also iData, isfield

% handle array of iData input
if numel(a) > 1
  b = []; link=[];
  for index=1:numel(a)
    if nargin == 2
      [b{index},link{index}] = feval(mfilename, a(index), field);
    elseif nargin == 3 && iscell(allfields)
      [b{index},link{index}] = feval(mfilename, a(index), field, allfields);
    elseif nargin == 3 && isstruct(allfields)
      b = [ b feval(mfilename, a(index), field, allfields) ];
    end
  end
  if nargout == 0 && ~isempty(inputname(1))
    assignin('caller',inputname(1),b);
  end
  return
end

if nargin < 3
  allfields = findfield(a);
end
if nargin == 3
  if isstruct(allfields)
    % we set the field attributes (add to existing ones if any)
    [b, link] = fileattrib(a, field); % get any existing attributes
    if ~isempty(link) % we can store there
      if iscell(link), link=link{1}; end
      if ~isempty(b) && isstruct(b)
        % catenate existing attributes with new ones
        af = [ fieldnames(allfields)  ; fieldnames(b) ];
        ac = [ struct2cell(allfields) ; struct2cell(b) ];
        [af,ii] = unique(af); % avoid duplicate fields
        b  = cell2struct(ac(ii),af,1);
      end
      a = set(a, link, allfields);
      b = a;
      % update output
      if nargout == 0 && ~isempty(inputname(1))
        assignin('caller',inputname(1),b);
      end
    end
    return
  elseif ~iscell(allfields) || ~ischar(allfields{1})
    b = a; % attribute can not be set
    return
  end
end

if iscell(field) && ischar(field{1}) && numel(field) > 1
  b = cell(1, numel(field)); link=b;
  for index=1:numel(field)
    [b{index},link{index}] = feval(mfilename, a, field{index}, allfields);
  end
  return
end

field = char(field);

% replace alias by its link
if any(strcmpi(field, getalias(a)))
  alias = getalias(a, field);
  if ischar(alias)
    field = alias;
  end
end

b = []; link = '';

if nargin == 1
  [status, b] = fileattrib(a.Source);
  link        = a.Source;
  if ~status, b = []; end
else
  
  if any(strcmp(field, allfields))
    [b, link] = iData_getAttribute(a, field);
  end
end

