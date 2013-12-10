function data = read_hdf4(filename)
% mhdf4read Wrapper to hdfinfo/hdfread which reconstructs the HDF4 structure
%
% The returned structure has:
% data.<path>...          the main branch holding the HDF4 data sets
% data.Attributes.<path>  the sub-structure holding all attributes with similar 
%                           structure as the main branch

% read file structure
try
  s = hdfinfo(filename);
catch
  data = [];
  return
end

% recursive call
[data, Attributes] = getGroup(s);

if isstruct(data) && ~isempty(Attributes)
  data.Attributes = Attributes;
end

% ------------------------------------------------------------------------------
function [data, Attributes] = getGroup(s)
  % getGroup: get a HDF4 array of elements
  %
  % input:
  %   s: HDF4 info element or array
  % output:
  %   data: datasets
  
  data = []; Attributes = [];
  
  if numel(s) > 1
    % we have an array of elements: we create as many data.(name) entries as necessary
    % and fill them with recursive calls
    for index=1:length(s)
      % a single element in the array
      this = s(index);
      
      % get field Name and default Attributes
      name       = getName(this, index);
      if isempty(Attributes)
        Attributes = getAttributes(this);
      end

      % handle group or other direct access data set
      if isfield(this, 'Vgroup')
        [this, Attribute] = getGroup(this);
      else
        % not a Vgroup
        Attribute  = getAttributes(this);
        this       = hdfread (this); 
      end
      
      % store
      data.(name)       = this;
      Attributes.(name) = Attribute;
    end
  else
    % a single Vgroup or root element

    [data, Attribute]  = getSingle(s); % will return a struct if needed
    Attributes = catStruct(Attributes, Attribute);
    
  end

% ------------------------------------------------------------------------------
function [data, Attributes] = getSingle(this)
  % getSingle: get a single HDF4 element
  %
  % input:
  %   this: HDF4 info element
  % output:
  %   data: dataset
  
  data = []; Attributes = getAttributes(this);
  
  % handle single element
  if isfield(this, 'Vgroup') && ~isempty(this.Vgroup)
    % recursive call for Vgroups
    name                               = getName(this);
    if isempty(name)
      [data,Attribute]                 = getGroup(this.Vgroup);
      Attributes = catStruct(Attributes, Attribute);
    else
      [data.(name), Attributes.(name)] = getGroup(this.Vgroup);
    end
  else
    % get data members
    list={'Raster8','Raster24','SDS','Vdata','Grid','Point','Swath'};
    for index=1:length(list)
      % test for existence of data sets
      if isfield(this, list{index}) && ~isempty(this.(list{index}))
        this_info = this.(list{index});
        this_name = getName(this_info);
        if length(this_info)==1
          if isempty(this_name)
            data = hdfread  (this_info);
            Attribute  = getAttributes(this_info);
            Attributes = catStruct(Attributes, Attribute);
          else
            data.(this_name) = hdfread  (this_info);
            Attribute.(this_name) = getAttributes(this_info);
            if strcmp(list{index}, 'Vdata') 
              data.(this_name) = cell2struct( ...
                data.(this_name), { this_info.Fields(:).Name }, 1);
            end
          end
          
        elseif length(this_info)> 1
          if isempty(this_name)
            [data,Attribute] = getGroup (this_info);
            Attributes = catStruct(Attributes, Attribute);
          else
            [data.(this_name),Attribute.(this_name)] = getGroup (this_info);
          end
        end
      end
      
    end % for list
    if isempty(data)
      fprintf(1, 'Unkown group/data type\n');
      this
    end
  end

% ------------------------------------------------------------------------------
function name = getName(this, index)
  % getName: get the HDF4 element Name
  
  name = '';
  if nargin < 2, index = []; end
  if ~isstruct(this) || length(this) > 1
    return
  end
  
  if isfield(this, 'Name')
    name = this.Name;
  else
    if isfield(this, 'Class'), name = this.Class;
    end
    if ~isempty(name) && ~isempty(index)
      name = [ name '_' num2str(index) ];
    end
  end
  % pretty-fy
  name(~isstrprop(name,'alphanum') | name == '.' | name == '-' | name == '+') = '_';
  if ~isempty(name) && ~isletter(name(1)),  name = [ 'x' name ]; end

  
function Attributes = getAttributes(this)
  % getAttributes: get the current level Attributes
  
  % get this level Attributes
  if isstruct(this)
    if isfield(this, 'Attributes')
      Attributes = this.Attributes;
    elseif isfield(this, 'DataAttributes')
      Attributes = this.DataAttributes;
    else Attributes = [];
    end
    % check if this is vector of attributes
    if numel(Attributes) > 1 && isfield(Attributes, 'Value') && isfield(Attributes, 'Name')
      Attributes = cell2struct({ Attributes(:).Value }, { Attributes(:).Name }, 2);
    end
    if isfield(this, 'Class')
      Attributes.NX_class = this.Class;
    end
  end

% ------------------------------------------------------------------------------
function s = catStruct(s1, s2)

  if     isempty(s1), s=s2; return;
  elseif isempty(s2), s=s1; return; end
  c1 = struct2cell(s1);
  c2 = struct2cell(s2);
  f1 = fieldnames(s1);
  f2 = fieldnames(s2);
  
  s = cell2struct([ c1 ; c2 ], [f1 ;f2 ], 1);
  
