function b = pack(a)
% b = pack(a) : compress iData storage to save memory
%
%   @iData/pack function to save memory when storing data sets
%   This includes to compare sparse/full storage for large matrices, and
%   reduce the Command history. Only the Signal, aliases and Axes are kept
%   so that unused Data items are removed.
%
% input:  s: object or array (iData)
% output: f: compressed object or array (iData)
% ex:     b=pack(a);
%
% Version: $Revision: 1057 $
% See also iData, iData/sparse, iData/full, iData/saveas

if numel(a) > 1
  b = zeros(iData, numel(a), 1);
  parfor index=1:numel(a)
    b(index) = pack(a(index));
  end
  b = reshape(b, size(a));
  if nargout == 0 & ~isempty(inputname(1))
    assignin('caller',inputname(1),b);
  end
  return
end

% extract Signal, Error, Monitor, Aliases and Axes
[alias_names, alias_links, alias_labels]      = getalias(a);
axis_links   = getaxis(a);
alias_values = cell(size(alias_names));
alias_ranks  = zeros(size(alias_values));
parfor index=1:length(alias_names)
  % get value if this is not set to default (Error, Monitor)
  if ~isempty(alias_links{index})
    alias_values{index} = get(a, alias_names{index});
  end
  % extract rank if this is an axis
  rank = find(strcmp(alias_names{index}, axis_links));
  if ~isempty(rank)
    alias_ranks(index) = rank(1);
  end
end
% now reconstruct a minimal object
b = copyobj(a);
b = setalias(b, getalias(b));
b.Data = [];
% and add aliases and axes from initial object
for index=1:length(alias_names)
  % create the alias and associate a value in Data
  if ~isempty(alias_values{index})
    try
      b.Data.(alias_names{index}) = alias_values{index};
      setalias(b, alias_names{index}, ['Data.' alias_names{index}], alias_labels{index});
    catch
      alias_ranks(index) = 0; % make sure invalid aliases do not become axes
    end
  end
end

for index=1:length(alias_names)
  if alias_ranks(index) > 0
    setaxis(b, alias_ranks(index), alias_names{index});
  end
end

% extract field type and size
[match, types, nelements]=findfield(b);

converted = '';

largemat = find(nelements > 1000);
match    = match(largemat);
types    = types(largemat);
nelements= nelements(largemat);
for index=1:length(nelements)
  f = match{index}; % field name
  d = get(b, f);    % content

  if ndims(d) > 2   % sparse only works with 1-2 d vector/matrix
    continue
  end
  if ~any(strcmp(class(d), {'double','single','logical','int32','int64','uint32','uint64'}))
    continue;
  end
  % convert d to either logical or double so that sparse can apply
  if ~strcmp(types{index}, 'double') && ~strcmp(types{index}, 'logical')
    d = double(d);
  end
  id = issparse(d);;
  if issparse(d)
    who_sparse = whos('d'); 
    d = full(d);
    who_full   = whos('d'); 
  else
    who_full   = whos('d');
    d = sparse(d);
    who_sparse = whos('d');
  end
  if ~id && who_sparse.bytes < who_full.bytes
    d = sparse(d); converted = [ converted f ' ' ]; set(b, f, d);
  elseif id && who_full.bytes < who_full.sparse                             
    d = full(d); converted = [ converted f ' ' ]; set(b, f, d);
  end
end

if ~isempty(converted)
  fprintf(1, '%s: Packed fields %s.\n', mfilename, converted);
end

% now reduce the size of the Command history
h = b.Command;
largemat = cellfun('length', h);
largemat = find(largemat > 1000);
for index=1:length(largemat)
  d = h{largemat(index)};
  d = [ d(1:50) ' ... ' d((end-50):end) ];
  h{largemat(index)} = d;
end
b.Command = h;

if nargout == 0 & ~isempty(inputname(1))
  assignin('caller',inputname(1),b);
end

