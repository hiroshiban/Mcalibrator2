function s = unique(a,dim,mode)
% s = unique(a,dim) : set unique iData objects axes with no repetitions
%
%   @iData/unique function to remove duplicates along data set axes
%     unique(a,dim) set unique along axis of rank dim. 
%       If dim=0, operates on all axes.
%   Alternatively, you can use 'isequal' to find unique data sets and remove 
%     duplicates.
%
% input:  a: object or array (iData)
%         dim: dimension to unique (int)
% output: s: data set with unique axes (iData)
% ex:     c=unique(a);
%
% Version: $Revision: 1057 $
% See also iData, iData/plus, iData/unique, iData/sort, iData/isequal
if ~isa(a, 'iData')
  iData_private_error(mfilename,['syntax is unique(iData, dim)']);
end

if nargin < 2, dim=1; end

% handle input iData arrays
if numel(a) > 1
  s = zeros(iData, numel(a), 1);
  parfor index=1:numel(a)
    s(index) = unique(a(index), dim);
  end
  s = reshape(s, size(a));
  return
end
cmd=a.Command;
s = copyobj(a);

[sn, sl] = getaxis(a, '0');   % label
sd = get(s,'Signal');         % data
se = get(s,'Error');
sm = get(s,'Monitor');

if dim > 0
  tounique=dim;
else
  tounique=1:ndims(a)
end
was_uniqueed=0;

for index=tounique
  x = getaxis(a, index);
  [x, uniquei] = unique(x);
  if length(uniquei) ~= size(a, index)
    toeval='';
    S.type='()';
    for j=1:ndims(a), 
      if j ~= index, S.subs{j}=':';
      else           S.subs{j}=uniquei; end
    end
    sd =subsref(sd, S);
    if numel(se) == numel(sd), se =subsref(se, S); end
    if numel(sm) == numel(sd), sm =subsref(sm, S); end
    setaxis(s, dim, x);
    was_uniqueed=1;
  end
end
if was_uniqueed
  s = setalias(s, 'Signal', sd, [ 'unique(' sl ')' ]);
  s = setalias(s, 'Error',  se);
  s = setalias(s, 'Monitor',sm);
  s.Command=cmd;
  s = iData_private_history(s, mfilename, a, dim);
end

