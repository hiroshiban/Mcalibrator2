function [attribute, f] = iData_getAttribute(in, field)
% search if there is a corresponding label (in Headers/Attributes)

  attribute = []; f=[];
  
  index = find(strcmp(field, in.Alias.Names));
  if ~isempty(index)
    field = in.Alias.Values{index(1)};
    if ~ischar(field)
      % can not store attributes when the Alias value is really a value (not a link)
      return
    end
  end
  
  if any(strfind(field, 'Attributes')) || any(strfind(field, 'Headers'))
    attribute = get(in, field);  % already an Attribute
    if ~isempty(attribute)
      f         = field;
    else
      % return the path to where Attributes should be stored
      [base, group, lastword] = getAttributePath(field);
      
      f         = [ base group 'Attributes.' lastword ];
    end
  end
  
  % 'field' contains the full path to Signal, e.g. 'Data.<path>'

  % if we use 'Headers' or 'Attributes' from e.g. read_anytext/looktxt
  % we e.g. relate in.Data.<field path> 
  %       to label in.Data.Headers.<field path>
  %       or       in.Data.Attributes.<field path>
  if isfield(in.Data, 'Attributes') || isfield(in.Data, 'Headers')
    if strncmp(field, 'Data.', length('Data.'))
      for f={[ 'Data.Headers.'    field( (length('Data.')+1):end ) ], ...
             [ 'Data.Attributes.' field( (length('Data.')+1):end ) ]}
        try
          attribute = get(in, f); % Data.Headers.<field>
          if ~isempty(attribute), return; end
        end
      end
    end
    
  end
    
  % if we use 'Attributes' from e.g. read_hdf/HDF or NetCDF/CDF
  % we e.g. relate in.Data.<group>.<field> 
  %      to label  in.Data.<group>.Attributes.<field>

  % get group and field names
  [base, group, lastword] = getAttributePath(field);
  list = { [ base group lastword '.Attributes' ], ...
           [ base group 'Attributes.' lastword ]};
  
  % we prepend the last word with Attributes. and check for existence
  for f=list
    try
      attribute = get(in, f{1}); % evaluate to get content of link
      if ~isempty(attribute), return; end
    end
  end
  
  if isempty(f),
    f = [ base group 'Attributes.' lastword ];
  end
  
% ------------------------------------------------------------------------------
  
function [base, group, lastword] = getAttributePath(field)
% function to split the entry name into basename, group and dataset
% duplicated from iData_getAttribute

  % get group and field names
  lastword_index = find(field == '.' | field == '/', 2, 'last'); % get the group and the field name
  if isempty(lastword_index)
    lastword = field; 
    group    = '';
    base     = '';                            % Attributes.<field>.
  elseif isscalar(lastword_index)
    lastword = field((lastword_index+1):end); 
    group    = field(1:lastword_index);
    base     = '';                            % <group>.Attributes.<field>
  else 
    lastword = field( (lastword_index(2)+1):end ); 
    group    = field( (lastword_index(1)+1):lastword_index(2) ); 
    base     = field(1:lastword_index(1));    % <basename>.<group>.Attributes.<field>
  end

