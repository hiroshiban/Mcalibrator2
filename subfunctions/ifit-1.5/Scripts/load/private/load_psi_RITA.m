function a=load_psi_RITA(a)
% function a=load_fig(a0)
%
% Returns an iData style dataset from a PSI RITA2 file (HDF5)
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

% handle input iData arrays
if numel(a) > 1
  b = [];
  for index=1:numel(a)
    b = [ b ; feval(mfilename, a(index)) ]; 
  end
  a = b;
  return
end

if isempty(findfield(a, 'RITA_2'))
  return
end

% RITA2 file identified...

% Alias a.Data.entry1.data members

if ~isempty(a.Data.entry1.data) && ~isempty(a.Data.entry1.RITA_2) && ~isempty(a.Data.entry1.control)
  data_alias = fieldnames(a.Data.entry1.data);
  for index=1:length(data_alias)
    setalias(a, data_alias{index}, [ 'Data.entry1.data.' data_alias{index} ]);
  end

  % Alias a.Data.entry1.RITA_2.detectorwindows.counts
  setalias(a, 'windowcounts', 'Data.entry1.RITA_2.detectorwindows.counts');
  setalias(a, 'Signal',       'Data.entry1.data.counts');
  setalias(a, 'Monitor',      'Data.entry1.control.data');
  setalias(a, 'Sample',       'Data.entry1.sample');
  t = findfield(a, {'temperature','magnetic','Qh','Qk','Ql','Qm','energy','energy_transfer', ...
                   'a1','a2','a3','a4','a5','a6'});
  if ~isempty(t)
    for index=1:length(t)
      % we should skip any Attributes items
      if isempty(strfind(t{index}, 'Attributes')) && isempty(strfind(t{index}, 'Headers'))
        this = fliplr(strtok(fliplr(t{index}), '.'));
        setalias(a, this, t{index});
      end
    end
  end

  % identify the scan variable -> index_axis (name, to be aliased)
  index_axis_std= 0;
  index_axis    = '';
  data_alias    = fieldnames(a.Data.entry1.data);
  for index=1:length(data_alias)
    member=get(a, [ 'Data.entry1.data.' data_alias{index} ]);

    % find the numeric member which varies most
    if ~isnumeric(member), continue; end
    % get middle blade for matrices
    if ~isvector(member), member=member(ceil(size(member,1)/2),:); end 
    member=double(member);
    if ndims(member)==2 && std(member) > index_axis_std
      if any(strcmp(data_alias{index}, {'Qh','Qk','Ql','energy_transfer'})) ...
              || (any(strcmp(data_alias{index}, {'a1','a2','a3','a4','a5','a6'})) && index_axis_std==0)
        index_axis_std = std(member);
        index_axis     = data_alias{index};
      end
    end
  end

  % all blades should be gathered as a 2nd returned object which gives the 
  % integrated counts per blade per scan step
  b = copyobj(a);
  windowcounts   = a.windowcounts;
  b.windowcounts = windowcounts(1:9, :);
  setalias(b, 'Signal', 'windowcounts');
  % extend the monitor so that it also spans along the blades
  m=double(a.Data.entry1.control.data)*ones(1,9);
  set(b, 'Monitor', m);
  b{1}=index_axis;  % scan axis
  b{2}=transpose(ones(size(m,1),1)*(1:9)); % blade/window axis
  label(b, 2, 'Window index');
  b.Label = [ 'Windows ' b.Label ];

  label(a, 1,'Pixels index X'); label(a, 2,'Pixels index Y');
  if ndims(a) == 3, label(a, 3, 'Scan step'); end

  a = [ a ; b ];
end
