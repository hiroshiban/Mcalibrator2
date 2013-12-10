function filename = iData_private_saveas_hdfnc(a, filename, format, root)
% private function to write HDF, CDF and NetCDF files
  % format='HDF','CDF','NC' (netCDF)
  % root  ='path where to start to save hierarchy' e.g. 'Data' or '' for all

  if nargin < 3, format='hdf5'; end
  if nargin < 4, root  =''; end

  % export all fields
  [fields, types, dims] = findfield(a);

  % this will store the list of fields to write
  mode='overwrite'; write_list={}; 
  attr_list       ={};  % attributes for HDF
  varAttribStruct = []; % attributes for CDF
  globalAttributes= []; % global attributes for CDF
  
  for index=1:numel(fields) % scan all field names
    if isempty(fields{index}), continue; end
    % ignore fields that do not match root level
    if ~isempty(root) && ~strncmp(root, fields{index}, length(root))
      continue;
    end
    
    % get the field value
    val=get(a, fields{index});
    if strcmp(types{index}, 'hdf5.h5string'), val = char(val.Data); end
    if isstruct(val), continue; end
    if iscellstr(val), 
      val=val(:);
      val(:, 2)={ ';' }; 
      val=val'; 
      val=[ val{1:(end-1)} ];
    end
    if ~isnumeric(val) && ~ischar(val), continue; end
    if isempty(val),                    continue; end % does not support empty values when writing CDF
    
    % has the field some 'Attributes' ?
    [dataset_attr, link] = fileattrib(a, fields{index}, fields);
    if strcmp(link, fields{index}) || ~isempty(strfind(fields{index}, 'Attributes'))
      continue;
    end
    % handle case where attributes are not a struct
    if ~isempty(dataset_attr) && ~isstruct(dataset_attr)
      if ischar(dataset_attr)
        new_attr.Comment = dataset_attr;
      else
        new_attr.Value = dataset_attr;
      end
      dataset_attr = new_attr;
    end
    
    % split field name into: n = [ group '.' dataset ]
    n = fields{index};
    
    % get group attributes (if any)
    p       = find(n == '.', 1, 'last');
    group   = n(1:(p-1)); % does not have a '.' at the end
    if ~isempty(p),
      group_attr = fileattrib(a, group, fields);
      dataset    = n((p+1):end);
    else 
      group_attr = [];
      dataset    = n;
    end
    % handle case where attributes are not a struct
    if ~isempty(group_attr) && ~isstruct(group_attr)
      if ischar(group_attr)
        new_attr.Comment = group_attr;
      else
        new_attr.Value = group_attr;
      end
      group_attr = new_attr;
    end
    
    % get rid of root level when specified
    if ~isempty(root)
      % we already have strncmp(root, fields{index}, length(root))
      % so just move forward and skip potential '.'
      n     = n((length(root)+1):end);
      if n(1)     == '.', n    =n(2:end); end
      group = group((length(root)+1):end);
      if ~isempty(group)
        if group(1) == '.', group=group(2:end); end
      end
    end
    
    % now assemble the list of items for CDF and HDF output (requires double memory)
    % direct write for NetCDF.
    
    % now handle different file formats: HDF5, CDF, NetCDF

    % CDF ----------------------------------------------------------------------
    if strcmpi(format,'cdf') && (isnumeric(val) || ischar(val))
    
      write_list = [ write_list , n, val ]; % add Variable
      
      % write dataset attributes
      if isstruct(dataset_attr) && ~any(strcmp(n, attr_list))
        for f = fieldnames(dataset_attr)' % write all attributes one-by-one
          if ~isempty(dataset_attr.(f{1})) && ~isstruct(dataset_attr.(f{1}))
            if ~isfield(varAttribStruct, f{1})
              varAttribStruct.(f{1}) = { n dataset_attr.(f{1}) };
            else
              varAttribStruct.(f{1}) = [ varAttribStruct.(f{1}) ; ...
                                       { n dataset_attr.(f{1}) } ];
            end
          end
        end
        attr_list{end+1} = n;
      end
      
      % write group attributes
      if isstruct(group_attr) && ~any(strcmp(group, attr_list))
        for f = fieldnames(group_attr)' % write all attributes one-by-one
          if ~isempty(group_attr.(f{1})) && ~isstruct(group_attr.(f{1})) ...
            && ~isfield(globalAttributes, f{1})
            globalAttributes.(f{1}) = group_attr.(f{1});
          end
        end
        attr_list{end+1} = group;
      end
      
      
    % HDF5 ---------------------------------------------------------------------
    elseif any(strcmpi(format,{'hdf','hdf5','h5','nx','nxs','n5'}))
      % the function hdf5write requires to write all (datasets+attributes) in 
      % one single shot. We assemble the list of items to write in a cell, and
      % then flush.
      
      n(n == '.')         = '/'; % handle path separator for HDF
      if isempty(group), group = '/';
      else               group(group == '.') = '/';
      end
      
      details.Location = group;
      details.Name     = dataset;
      write_list       = [ write_list , details, val ];
      
      % write dataset attributes
      if isstruct(dataset_attr) && ~any(strcmp(n, attr_list))
        attr_details.AttachedTo = n;
        attr_details.AttachType = 'dataset';
        for f = fieldnames(dataset_attr)' % write all attributes one-by-one
          attr_details.Name = f{1};
          if ~isempty(dataset_attr.(f{1})) && ~isstruct(dataset_attr.(f{1}))
            write_list       = [ write_list , attr_details, dataset_attr.(f{1}) ];
          end
        end
        attr_list{end+1} = n;
      end
      
      % write group attributes
      if isstruct(group_attr) && ~any(strcmp(group, attr_list))
        attr_details.AttachedTo = group;
        attr_details.AttachType = 'group';
        for f = fieldnames(group_attr)'
          attr_details.Name = f{1}; % write all attributes one-by-one
          if ~isempty(group_attr.(f{1})) && ~isstruct(group_attr.(f{1}))
            write_list       = [ write_list , attr_details, group_attr.(f{1}) ];
          end
        end
        attr_list{end+1} = group;
      end
      
      % add root level attributes (if any, only once)
      root_attr = fileattrib(a, 'Data', fields);
      if isstruct(root_attr) && ~any(strcmp('/', attr_list))
        attr_details.AttachedTo = '/';
        attr_details.AttachType = 'group';
        for f = fieldnames(root_attr)'
          attr_details.Name = f{1}; % write all attributes one-by-one
          if ~isempty(root_attr.(f{1})) && ~isstruct(root_attr.(f{1}))
            write_list       = [ write_list , attr_details, root_attr.(f{1}) ];
          end
        end
        attr_list{end+1} = '/';
      end
    
    % NetCDF -------------------------------------------------------------------
    elseif strcmpi(format,'nc')
      if strcmp(mode, 'overwrite') % first access: create file
        if ~isempty(dir(filename)), delete(filename); end
        ncid = netcdf.create(filename, 'CLOBBER');
        mode = 'append';
      end
      % create dimensions
      if isvector(val), Dims=length(val); 
      else              Dims=size(val); end
      dimId = [];
      for d=1:length(Dims)
        dimId = [ dimId netcdf.defDim(ncid, [ n '_' num2str(d) ], Dims(d) ) ];
      end
      % get the variable storage class
      c = class(val);
      switch class(val)
        case 'double', t='NC_DOUBLE';
        case 'single', t='NC_FLOAT';
        case 'int8',   t='NC_BYTE';
        case 'char',   t='NC_CHAR';
        case 'int16',  t='NC_SHORT';
        case 'int32',  t='NC_INT';
        % netCDF4 types are converted to NetCDF3
        case 'uint8',  val=int8(val);  t='NC_BYTE';
        case 'uint16', val=int16(val); t='NC_SHORT';
        case 'uint32', val=int32(val); t='NC_INT';
        case 'uint64', val=int32(val); t='NC_INT';
        case 'int64',  val=int32(val); t='NC_INT';
        otherwise, t = ''; continue;
      end
      
      if isempty(t)
        fprintf(1, [mfilename  ': Failed to write ' n ' ' c ' ' mat2str(size(val)) '\n' ]);
        continue
      end
      % create the Variable, and set its value
      varid = netcdf.defVar(ncid, n, t, dimId);
      netcdf.endDef(ncid);
      netcdf.putVar(ncid, varid, val);
      netcdf.reDef(ncid);
    end
  end % for

  % close netCDF file
  if strcmpi(format,'nc')
    netcdf.close(ncid);
  elseif strcmpi(format,'cdf')
    args = {};
    if ~isempty(globalAttributes)
      args = [ args, 'globalAttributes', globalAttributes ];
    end
    if ~isempty(varAttribStruct)
      args = [ args, 'VariableAttributes', varAttribStruct ];
    end
    args = [ args, 'WriteMode','overwrite' ];
    cdfwrite(filename, write_list, args{:}); % automatically adds .cdf
  elseif any(strcmpi(format,{'hdf','hdf5','h5','nx','nxs','n5'}))
    hdf5write(filename, write_list{:}, 'WriteMode','overwrite');
  end
 
end % saveas_hdfnc

