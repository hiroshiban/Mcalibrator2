function s = read_cdf(filename)
% mcdfread Wrapper to cdfread which reconstructs the CDF structure

% turn OFF file validation to improve performance
cdflib.setValidate('VALIDATEFILEoff');

% gather fields and avoid creating Date objects
[data, info] = cdfread(filename, ...
  'CombineRecords',true, 'ConvertEpochToDatenum',true);

if iscell(data)
  % data is a cell array
  % info.Variables contains the field names
  
  % setup CDF structure and get Global Attributes
  s.Name       = '/';
  s.Filename   = filename;
  s.Group      = [];
  s.Format     = info.Format;
  s.Attributes = info.GlobalAttributes;

  % reconstruct all fields in there
  for index=1:length(data)
    this_field=info.Variables{index};
    if strncmp(this_field,'Data_',5)
      this_field = this_field(6:end);
    end
    flag = 0; % set when we manage to store the variable
    if any(this_field == '.') && ~any(isspace(this_field))
      try
        eval([ 's.Variables.' this_field '= data{index};' ]);
        flag = 2;   % assign through eval (this_field = 'blah.blah.blah')
      end
    end
    if flag == 0
      this_field               = genvarname(this_field);
      s.Variables.(this_field) = data{index};
      flag = 1;     % direct assign
    end
    if flag
      % are there related attributes ?
      attribute = info.VariableAttributes;
      if isstruct(attribute)
        % search for a member which is a Mx2 cell
        attribute  = struct2cell(attribute);
        attr_index = cellfun(@iscell, attribute);
        if size(attribute{attr_index},2) == 2
          attribute = attribute{attr_index};
        else
          attribute = [];
        end
      end
      if ~isempty(attribute)
        index = strcmp(this_field, attribute(:,1));
        if any(index)
          % use location [ base group 'Attributes.' lastword ]
          if flag == 1      % direct assign
            s.Attributes.(this_field) = attribute{find(index),2};
          elseif flag == 2  % assign through eval (this_field = 'blah.blah.blah')
            try
              eval([ 's.Attributes.' this_field '= attribute{find(index),2};' ]);
            end
          end
        end
      end
    end % if flag
    
  end

else
  s = data;
end

