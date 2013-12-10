function a=load_ill_tas(a)
% function a=load_ill_tas(a)
%
% Simple postprocessing for ILL/TAS files.
% Supports ILL TAS files, including those with multidetectors.
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

if ~isa(a,'iData')
  a = load(iData,a,'ILL TAS');
  return
end

% handle input iData arrays
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index));
  end
  return
end

a=iData(a);

% re-assign DATA in case the file has more than one data block (MULTI, ...)
try
  DATA  = a.MetaData.DATA;
catch
  DATA  = [];
end
if isempty(DATA), DATA=a.Signal; end
setalias(a,'Signal',DATA,[ 'Data CNTS' ]);

try
  STEPS = a.Data.STEPS;
catch
  STEPS=[];
end
% get the main data block header
[columns_header, data]   = findstr(a, 'DATA_:','case');
if iscell(columns_header)
  [dummy, sorti] = sort(cellfun('prodofsize', columns_header)); 
  
  columns_header = columns_header{sorti(end)};
  data           = data{sorti(end)};
end

if isempty(columns_header), 
  warning([ mfilename ': The loaded data set ' a.Tag ' is not an ILL TAS data format.' ]);
  return; 
end
if iscell(columns_header)
  columns_header   = columns_header{1};
end
% detect if this is a MULTI detector file
try
  MULTI  = a.MetaData.MULTI; 
  setalias(a, 'MULTI', 'this.Data.MetaData.MULTI', 'Multidetector');
catch
  MULTI = [];
end

% Find spaces and determine proper aliases for the columns
columns = strread(columns_header,'%s','delimiter',' ;');
% restrict to the number of columns in DataBlock
c       = size(a, 2);
columns = columns(~cellfun('isempty', columns));
columns = columns((end-c+1):end);

% check if a scan step exists
if ~isempty(STEPS)
  steps_val=struct2cell(STEPS);
  steps_lab=fieldnames(STEPS);
  STEPS=[];
  % get the first non zero step
  for index=1:length(steps_val)
    if abs(steps_val{index}) > 1e-4 && isempty(STEPS)
      STEPS = steps_lab{index};
    end
  end
end
% compute the normalized variance of each column
index_hkle=[]; % index of QH QK QL EN columns
index_m12 =[]; % index of M1 M2 monitors
index_temp=[]; % index for temperatures
index_pal =[]; % index for polarization analysis
Variance  = zeros(1,length(columns));
is_pal    = '';

for j=1:length(columns)
  setalias(a,columns{j},a.Signal(:,j)); % create an alias for each column
  % use STEPS
  if any(strcmpi(columns{j}, {'QH','QK','QL','EN'}))  || ...
    (~isempty(STEPS) && any(strcmpi(columns{j}, STEPS))) || ...
    (~isempty(STEPS) && any(strcmpi([ 'D' columns{j} ], STEPS)))
    if isempty(find(index_hkle == j)), index_hkle = [ index_hkle j ]; end
  end
  % and other usual columns
  if any(strcmpi(columns{j}, {'M1','M2'}))
    index_m12 = [ index_m12 j ];
  end
  if any(strcmpi(columns{j}, {'TT','TRT'}))
    index_temp= [ index_temp j ];
  end
  if strcmpi(columns{j}, {'PAL'})     % polarized mode
    index_pal= [ index_pal j ];
    is_pal='PAL';
  elseif strcmpi(columns{j}, {'ROI'}) % IMPS mode
    index_pal= [ index_pal j ];
    is_pal='ROI';
  end
  if ~any(strcmpi(columns{j},{'PNT','CNTS','TI'}))
    if length(a.Signal(:,j))
      Variance(j) = sum( abs(a.Signal(:,j)-mean(a.Signal(:,j)) )) /length(a.Signal(:,j));
    end
  end
end

% Signal is in CNTS field, 1st axis is probably field with
% remaining greatest variance
TT = [];
if ~isempty(index_temp)
  TT = mean(a.Signal(:,index_temp(1)));
else
  index_temp=findfield(a, {'TT','TRT'}, 'case');
  if ~isempty(index_temp), TT = getfield(a, index_temp); end
end

FX = []; KFIX = [];
index_fx  =findfield(a, 'FX', 'case'); 
if ~isempty(index_fx), FX = get(a, index_fx{1}); end
index_kfix=findfield(a, 'KFIX', 'case');
if ~isempty(index_fx), KFIX = get(a, index_kfix{1}); end

% get the monitor
if ~isempty(index_m12)
  [dummy, index]=max(sum(a.Signal(:,index_m12)));
  index_m12 = index_m12(index);
  setalias(a,'Monitor',columns{index_m12},[ 'Monitor ' columns{index_m12} ]);
end
% try with usual scanned variables 'QH','QK','QL','EN'
index = [];
if ~isempty(index_hkle)
  [dummy, index]=max(Variance(index_hkle));
  if dummy > 1e-3
    index = index_hkle(index);
  end
end
if isempty(index)
  [dummy, index]=max(Variance); % then set axis as the one that varies the most
end


% retrieve specific information
try
  LOCAL = a.Attributes.MetaData.LOCAL; LOCAL=strtrim(LOCAL(7:end));
catch
  LOCAL='';
end
try
  TITLE = a.Attributes.MetaData.TITLE; TITLE=strtrim(TITLE(7:end));
catch
  TITLE='';
end
try
  USER  = a.Attributes.MetaData.USER;  USER =strtrim(USER(7:end));
catch
  USER='';
end
try
  EXPNO = a.Attributes.MetaData.EXPNO; EXPNO=strtrim(EXPNO(7:end));
catch
  EXPNO='';
end
try
  INSTR = a.Attributes.MetaData.INSTR; INSTR=strtrim(INSTR(7:end));
catch
  INSTR='';
end
try
  DATE  = a.Attributes.MetaData.DATE;  DATE =strtrim(DATE(7:end));
catch
  DATE='';
end
try
  COMND  = a.Attributes.MetaData.COMND;  COMND =strtrim(COMND(7:end));
catch
  COMND='';
end

setalias(a, 'COMND', 'this.Data.Attributes.MetaData.COMND', 'TAS command');
setalias(a, 'INSTR', 'this.Data.Attributes.MetaData.INSTR', 'Instrument used');
setalias(a, 'EXPNO', 'this.Data.Attributes.MetaData.EXPNO', 'Experiment number');
setalias(a, 'TITL',  'this.Data.Attributes.MetaData.TITLE', 'Dataset title');
% update object
if ~isempty(DATE), a.Date = DATE; end
a.User = [ EXPNO ' ' USER '/' LOCAL '@' INSTR ];
if isempty(TITLE), a.Title= [ COMND ';' a.Title ];
else a.Title= [ TITLE ';' a.Title ]; end
a.Title=regexprep(a.Title,'\s+',' ');


% set Signal and default axis

if isempty(MULTI)
  setalias(a,'Signal','CNTS',[ 'Data CNTS' ]);  % has been defined in DATA_ columns
  setaxis(a,1,columns{index});
else
  setalias(a,'Signal', 'MULTI',[ 'Data CNTS' ]);  % has been defined from MULTI_
  setalias(a,'Channel',1:size(MULTI,2), 'Detector channel');
  setaxis(a,1,columns{index});
  setaxis(a,2,'Channel');
  setalias(a,'Monitor', double(get(a, columns{index_m12})) * 1:size(MULTI,2));
end
% make up Signal label
xl = xlabel(a);
if isempty(xl), xl = getaxis(a,'1'); end
if ~isempty(TT) & isnumeric(TT), xl = sprintf('%s T=%.2f K',xl,TT); end
if ~isempty(FX) & isnumeric(FX), 
  if ~isempty(KFIX) & isnumeric(KFIX)
    if FX == 1, xl = sprintf('%s Ki=%.2f',xl,KFIX);
    else        xl = sprintf('%s Kf=%.2f',xl,KFIX);
    end
  end
end
xlabel(a, xl);

% handle polarization analysis files
if ~isempty(index_pal)
  % get number of PAL states
  pal = unique(DATA(:,index_pal(1)));
  b = [];
  for j=1:length(pal)
    % create one iData per PAL state
    index_rows = find( DATA(:,index_pal(1)) == pal(j) );
    this_b = a(index_rows, :);
    title(this_b, [ title(this_b) ' [' is_pal '=' num2str(j) ']' ]);
    this_b.Title = [ is_pal '=' num2str(j) ';' this_b.Title  ];
    b = [ b this_b ];
  end
  a = b;
end
  
