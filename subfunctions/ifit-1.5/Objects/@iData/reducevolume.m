function s = reducevolume(a, R)
% h = reducevolume(s, factor) : reduce an iData object size
%
% B = REDUCEVOLUME(A, [Rx Ry Rz ... ]) reduces the number
%    of elements in the object by only keeping every Rx element in the x
%    direction, every Ry element in the y direction, and every Rz element
%    in the z direction and so on. 
% B = REDUCEVOLUME(A, R)
%    If a scalar R is used to indicate the amount or
%    reduction instead of a vector, the reduction is assumed to
%    be R on all axes. 
%
% B = REDUCEVOLUME(A)
%    When omitted, the volume/size reduction is performed on bigger axes until
%    the final object contains less than 1e6 elements.
%
% Version: $Revision: 1035 $
% See also iData, reducevolume,plot, iData/plot, iData/size

% rebinning object so that its number of elements is smaller 

if nargin == 1
  R = []; % will guess to reduce down to 1e6
end

% handle input iData arrays
if numel(a) > 1
  s = zeros(iData, numel(a), 1);
  parfor index=1:numel(a)
    s(index) = feval(mfilename, a(index), R);
  end
  s = reshape(s, size(a));
  return
end

% determine best reduction factor
if ischar(R) || isempty(R)
  S  = size(a);
  R  = ones(size(S));
  S0 = S;
  
  % loop until we get les than 1e6 elements
  while prod(S) > 1e6
    % identify the biggest axis, and reduce it by increasing R
    for index=1:length(R)
      [dummy, j] = sort(S);
      % S(j(end)) is the biggest element
      R(j(end)) = R(j(end))+1;
      S = S0 ./ R;
    end
  end
 
end

% case of event data sets
if isvector(a)
  if length(R) > 1, R = max(R); end
elseif isnumeric(R) && length(R) == 1
  % R is scalar and object is not vectorial
  R = R*ones(1, ndims(a));
end

s = copyobj(a);
S = [];
S.type='()';
S.subs=cell(1,length(R));

% scan dimensions and rebin them
for index=1:length(R)
  lx = getaxis(s, index);
  if isvector(lx), lx=length(lx);
  else             lx=size(lx,index); end
  if R(index) > 1
    S.subs{index} = ceil(1:R(index):lx);
  else
    S.subs{index} = ':';
  end
end

% perform rebinning
s = subsref(s, S);


