function s = isequal(a,b)
% c = isequal(a,b) : full numerical equality comparison of iData objects
%
%   @iData/eq (==) exact equality comparison operator on Signal, Source,
%   Label, Title, Monitor
%
% input:  a: object or array (iData or numeric)
%         b: object or array (iData or numeric)
% output: c: logical array indicating equal objects (iData)
% ex:     d=isequal(a,b);
%
% Version: $Revision: 1035 $
% See also iData, iData/find, iData/gt, iData/lt, iData/ge, iData/le, iData/ne, iData/eq

if nargin ==1
	b=[];
end

if numel(a) > 1
  s = [];
  for index=1:numel(a)
    s = [ s ; feval(mfilename, a(index), b) ];
  end
  return
end
% now 'a' is a single object

if all(isempty(b))
    s = isempty(a);
    return
end
if any(~isa(b, 'iData'))
    s = false;
    return
end

% treat single 'a' object and compare with 'b': numel(a) == 1
% 'b' can be an array
sources = get(b, 'Source');
titls   = get(b, 'Title');
labs    = get(b, 'Label');
signala = getaxis(a, 0);
signalb = getaxis(b, 0);

if numel(b) > 1
  % compare a single 'a' with an array 'b'
  s = strcmp(a.Source, sources) & strcmp(a.Title, titls) & strcmp(a.Label, labs) ...
    & cellfun(@(x) isequal(x,signala) ,signalb);
else
  % compare a single 'a' with a single 'b'
  s = strcmp(a.Source, sources) & strcmp(a.Title, titls) & strcmp(a.Label, labs) ...
    & isequal(signala ,signalb);
end


