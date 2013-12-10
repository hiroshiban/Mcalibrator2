function b=iData_struct2iData(a)
% iData_struct2iData: converts a structure into an iData

  persistent fb

  if isempty(fb), fb=fieldnames(iData); end

  f  = fieldnames(a);
  b  = iData; 
  if isfield(a, 'Data')   % start by storing the raw Data
    b.Data = a.Data;
  end
  for index=1:length(f)
    if any(strcmp(f{index},fb)) && ~strcmp(f{index}, 'Data')
      b = set(b,f{index}, a.(f{index}));
    end
  end
    
  if ~isfield(a, 'Data')   % store whole file content if possible.
    b.Data = a;
%  else
%    disp(['iData: warning: could not import all fields from structure.' ]);
  elseif isfield(a, 'Headers')
    b.Data.Attributes = a.Headers;
    b=setalias(b, 'Attributes', 'Data.Attributes', 'Headers (text)' );
   elseif isfield(a, 'Attributes')
    b.Data.Attributes = a.Attributes;
    b=setalias(b, 'Attributes', 'Data.Attributes', 'Headers (text)' );
  end
  if isfield(a, 'Format')
    setalias(b, 'Format', a.Format);
  end
  if isfield(a, 'Command')
    b.Command = a.Command;
  end
  if ~iscellstr(b.Command)
    b.Command = { b.Command };
  end
  
  if isempty(b.Command), b.Command= cellstr('iData(<struct>)'); end
  
  [pathname,filename,ext] = fileparts(b.Source);
  if isfield(b.Data, 'MetaData')
    b=setalias(b, 'MetaData', 'Data.MetaData', [ 'MetaData from ' filename ext ]);
    b=load_clean_metadata(b);
  end
  
  % ------------------------------------------------------------------------------
  
function a=load_clean_metadata(a, loaders, filenames)
% test each field of MetaData and search for equal aliases
  this = a.Data.MetaData;
  meta_names = fieldnames(this);
  alias_names=getalias(a);
  %treat each MetaData
  for index=1:length(meta_names)
    if numel(getfield(this, meta_names{index})) > 1000
    for index_alias=1:length(alias_names)
      % is it big and equal to an alias value ?
      if isequal(getfield(this, meta_names{index}), get(a, alias_names{index_alias}))
        % yes: store alias in place of MetaData
        this = setfield(this, meta_names{index}, getalias(a, alias_names{index_alias}));
        break
      end
    end % for
    end % if
  end
  a.Data.MetaData = this;

