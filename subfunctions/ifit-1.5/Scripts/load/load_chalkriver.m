function a=load_chalkriver(a0)
% function a=load_chalkriver(a0)
%
% Returns an iData style dataset from a Chalk River CNBC data file
% each initial data file may contain more than one record. Also handles multiwire detectors.
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

if ~isa(a0,'iData')
  a = load(iData,a0,'ChalkRiver');
  return
end

% handle input iData arrays
if numel(a0) > 1
  a = [];
  for index=1:numel(a0)
    a = [ a feval(mfilename, a0(index)) ];
  end
  return
end

% CNBC files have a Run, Seq and Rec field
if isempty(findfield(a0,'Run','exact')) || isempty(findfield(a0,'Seq','exact')) ...
|| isempty(findfield(a0,'Rec','exact'))
  warning([ mfilename ': The loaded data set ' a0.Tag ' from ' a0.Source ' is not a Chalk River data format.' ]);
  a = a0;
  return
end

a = [];
% split the initial iData if more than one section exists
% the initial object.Data should only contain Attributes, MetaData and Run_* fields
f = fieldnames(a0.Data);
record_index=0;
Instrument='';
% first we extract the Records in case the file has multiple blocks
for index=1:length(f)
  if strncmp(f{index}, 'Run',3)
    % extract only one record at a time
    record_index = record_index+1;
    this = copyobj(a0);
    % % get Run Data for this block (if multiple records)
    Data = this.Data;
    Record  = Data.(f{index});
    if isfield(Data, 'Attributes')   % get Attributes for this block
      Record.Attributes = Data.Attributes.(f{index});
      if isfield(Data.Attributes, 'MetaData')  % get MetaData for this block
        Record.MetaData = Data.Attributes.MetaData;
        this_f = fieldnames(Data.Attributes.MetaData);
        index_file   = find(strncmp(this_f, 'File', 4));  % also contains Instrument and Date
        if record_index <= length(index_file)
          Record.File=Data.Attributes.MetaData.(this_f{index_file(record_index)});
          % extract the instrument name (follows 'File')
          dummy = Record.File(length('File '):end);
          if isempty(Instrument)
            [Instrument, dummy] = strtok(dummy, ': '); % instrument
          end
          date_index = strfind(dummy, 'Date ');
          date_str   = dummy((date_index+length('Date ')):end);
          this.Date  = strtrim(strrep(date_str, ';', ''));  % date (creation)
        end
        if ~isempty(Instrument), Record.Instrument = Instrument; end
        index_signal = find(strncmp(this_f, 'Sig', 3));   % column headers
        if record_index <= length(index_signal)
          columns=Data.Attributes.MetaData.(this_f{index_signal(record_index)});
          % the keyword 'Sig' is always followed by a second word, separated with ' ' or '='
          % we thus need to catenate these two words, that is remove spaces after 
          % 'Sig', and change any occurence of '=' into '_'
          sig_index = strfind(columns, 'Sig');
          % scan columns for '=' and suppress all spaces following
          for index_sign=[ strfind(columns, '=') strfind(columns, ':') ]
            spaces = isspace(columns((index_sign+1):end));
            if ~isempty(spaces) && spaces(1)          % starts with a space ?
              spaces_length = min(find(spaces == 0)); % first non space
              columns((index_sign+1):(index_sign+spaces_length)) = ';';  % replace with ';'
            end
          end
          % now suppress all ';' signs (also used for EOL)
          columns = strrep(columns, ';', '');
          columns = strrep(columns, '=', '_');
          columns = strrep(columns, ':', '_');
          % clean all non alphanum chars
          columns(find(~isstrprop(columns, 'alphanum') & columns ~= '_' & columns ~= ' ')) = '';
          % split into words
          columns = strread(columns, '%s')';
          Record.columns=columns;
        end
      end
    else
      Record.columns =[];
      Record.File='';
      Record.Instrument='';
    end % if Attributes
    
    this.Data=Record;
    lab = '';
    if isfield(Record, 'Instrument'), 
      setalias(this, 'Instrument', 'Data.Instrument'); lab = [ lab Record.Instrument ]; end
    if isfield(Record, 'Run'), 
      setalias(this, 'Run', 'Data.Run'); lab = [ lab ' Run:' num2str(Record.Run) ]; end
    if isfield(Record, 'Rec'), 
      setalias(this, 'Rec', 'Data.Rec'); lab = [ lab ' Rec:' num2str(Record.Rec) ]; end
    if isfield(Record, 'Seq'), 
      setalias(this, 'Seq', 'Data.Seq'); lab = [ lab ' Seq:' num2str(Record.Seq) ]; end
    if ~isempty(lab) this.Label=lab; end
    this = setalias(this, 'Signal',''); % reset Signal to the biggest block
    
    this_size = size(this,2); % the full record
    % get the real number of columns
    Sig_columns = find(strncmp(columns, 'Sig', 3));
    columns = columns([ 1:(min(Sig_columns)-1+length(Sig_columns)) ]);
    % assign columns
    if this_size >= length(columns)
      block = getalias(this, 'Signal'); % where is the largest block ?
      new_this = [];
      
      for i=1:length(columns)
        if length(Sig_columns) >= 1 && this_size <= length(columns)
          % listed Sig columns: split into as many Sig columns as needed
          if isfield(this, columns{i})
            columns{i} = [ columns{i} '_' num2str(i) ];
          end
          this = setalias(this, columns{i}, [ block '(:,' num2str(i) ')' ]); % set columns
          if strncmp(columns{i}, 'Mon', 3)
            setalias(this, 'Monitor', columns{i});
          end
          % add the object to the output only if there is a Sig column
          if strncmp(columns{i}, 'Sig', 3)
            this_toadd = copyobj(setalias(this, 'Signal', columns{i}));  % the Signal is set to the last Sig column
            this_toadd.Title = [ this_toadd.Title '#' columns{i} ];
            this_toadd.Label = [ this_toadd.Label '#' columns{i} ];
            new_this = [ new_this this_toadd ];
          end
        elseif this_size > length(columns) && length(Sig_columns) == 1
          % this is a multi-wire record: only one Sig record for a matrix
          if strncmp(columns{i}, 'Sig', 3)
            this_toadd = copyobj(setalias(this, columns{i}, [ block '(:,' num2str(i) ':end)' ]));
            this_toadd = setalias(this_toadd, 'Signal', columns{i});
            setalias(this_toadd, 'Channel', 1:(this_size-1), 'Multi wire channel');
            setaxis(this_toadd, 1, columns{1});   % Y vertical
            setaxis(this_toadd, 2, 'Channel');
            new_this = [ new_this this_toadd ];
          else
            setalias(this, columns{i}, [ block '(:,' num2str(i) ')' ]);
          end
        end
      end % for
      if ~isempty(new_this)
        this = new_this; clear new_this;
      end
    end
    a = [ a this ];
  end % if Run
end % for

if isempty(a), a = a0; end

