function c = iData_private_binary(a, b, op, varargin)
% iData_private_binary: handles binary operations
%
% Operator may apply on an iData array and:
%   a scalar
%   a vector/matrix: if its dimensionality is lower than the object, 
%     it is replicated on the missing dimensions
%   a single iData object, which is then used for each iData array element
%     operator(a(index), b)
%   an iData array, which should then have the same dimension as the other 
%     iData argument, in which case operator applies on pairs of both arguments.
%     operator(a(index), b(index))
%
% operator may be: 'plus','minus','combine'
%                  'times','rdivide', 'ldivide','mtimes','mrdivide','mldivide', 'conv', 'xcorr'
%                  'lt', 'gt', 'le', 'ge', 'ne', 'eq', 'and', 'or', 'xor', 'isequal'
%
% Contributed code (Matlab Central): 
%   genop: Douglas M. Schwarz, 13 March 2006
%
% Version: $Revision: 1057 $

% for the estimate of errors, we use the Gaussian error propagation (quadrature rule), 
% or the simpler average error estimate (derivative).

% handle input iData arrays

if (isa(a, 'iData') & numel(a) > 1)
  c = [];
  if isa(b, 'iData') & numel(b) == numel(a)
    % add element to element
    c = zeros(iData, numel(a), 1);
    parfor index=1:numel(a)
      c(index) = iData_private_binary(a(index), b(index), op);
    end
  elseif isempty(b)
    % process all elements from vector
    c = a(1);
    for index=2:numel(a)
      c = iData_private_binary(c, a(index), op);
    end
    return
  elseif isa(b, 'iData') & numel(b) ~= numel(a) & numel(b) ~= 1
    iData_private_warning('binary', ...
    [ 'If you wish to force this operation, use ' op '(a,b{0}) to operate with the object Signal, not the object itself (which has axes).' ]);
    iData_private_error('binary',...
    [ 'Dimension of object arrays do not match for operator ' op ': 1st is ' num2str(numel(a)) ' and 2nd is ' num2str(numel(b)) ]);
  else
    % add single element to vector
    c = zeros(iData, numel(a), 1);
    parfor index=1:numel(a(:))
      c(index) = iData_private_binary(a(index), b, op);
    end
  end
  if ~isempty(b)
    c = reshape(c, size(a));
  end
  return
elseif isa(b, 'iData') & numel(b) > 1
  c = zeros(iData, numel(b), 1);
  parfor index=1:numel(b)
    c(index) = iData_private_binary(a, b(index), op);
  end
  return
end

if isa(a,'iFunc')
  a = subsref(b, struct('type','()','subs', a) );
elseif isa(b, 'iFunc')
  b = subsref(a, struct('type','()','subs', b) );
end

if (isempty(a) || isempty(b))
  if any(strcmp(op, {'plus','minus','combine'}))
    if     isempty(a), c=b; return;
    elseif isempty(b), c=a; return; end
  else c = []; return; 
  end
end

iData_private_warning('enter',[ mfilename ' ' op ]);

if isa(a, 'iData')
  cmd=a.Command;
elseif isa(b, 'iData')
  cmd=b.Command;
end

% handle special case of operation with transposed 1D data set and an other one
if (~isscalar(a) && isvector(a) && size(a,1)==1 && ~isscalar(b) && ~isvector(b)) || ...
   (~isscalar(b) && isvector(b) && size(b,1)==1 && ~isscalar(a) && ~isvector(a))
  transpose_ab = 1;
  a = permute(a,[ 2 1 3:length(size(a)) ]);
  b = permute(b,[ 2 1 3:length(size(b)) ]);
else
  transpose_ab = 0;
end

% get Signal, Error and Monitor for 'a' and 'b'
if isa(a, 'iData') & isa(b, 'iData') 
  if strcmp(op, 'combine')
    [a,b] = union(a,b);     % perform combine on union
  else
    [a,b] = intersect(a,b); % perform operation on intersection
  end
end

% the p1 flag is true when a monitor normalization is required (not for combine)
if strcmp(op, 'combine'), p1 = 0; else p1 = 1; end
if ~isa(a, 'iData')   % constant/scalar
  s1= a; e1=0; m1=0;
  c = copyobj(b);
else
  s1 = subsref(a,struct('type','.','subs','Signal'));
  e1 = subsref(a,struct('type','.','subs','Error'));
  m1 = subsref(a,struct('type','.','subs','Monitor'));
  c  = copyobj(a);
end
if ~isa(b, 'iData') % constant/scalar
  s2= b; e2=0; m2=0;
else
  s2 = subsref(b,struct('type','.','subs','Signal'));
  e2 = subsref(b,struct('type','.','subs','Error'));
  m2 = subsref(b,struct('type','.','subs','Monitor'));
end
if all(m1(:)==0) && all(m2(:)==0), m1=0; m2=0; end

% do test on dimensionality for a vector/matrix input
% use vector duplication to fill iData dimensionality (repmat/kron)

% the 'real' signal is 'Signal'/'Monitor', so we must perform operation on this.
% then we compute the associated error, and the final monitor
% finally we multiply the result by the monitor.

% 'y'=normalized signal, 'd'=normalized error, 'p1' set to true when normalization
% to the Monitor is required (i.e. all operations except combine).
if not(all(m1(:) == 0 | m1(:) == 1)) & p1, 
  y1 = genop(@rdivide, s1, m1); d1 = genop(@rdivide,e1,m1); 
else y1=s1; d1=e1; end
if not(all(m2(:) == 0 | m2(:) == 1)) & p1, 
  y2 = genop(@rdivide,s2,m2); d2 = genop(@rdivide,e2,m2); 
else y2=s2; d2=e2; end

% operation
switch op
case {'plus','minus','combine'}
  if strcmp(op, 'combine'), 
       s3 = genop( @plus,  y1, y2); % @plus without Monitor nomalization (y=s)
       if isscalar(m1), m1=m1*ones(size(s1)); end
       if isscalar(m2), m2=m2*ones(size(s2)); end
  else s3 = genop( op,     y1, y2); end
  i1 = isnan(y1(:)); i2=isnan(y2(:));
  % if NaN's are found (from interp), use non NaN values in the other data set 
  if any(i1) && ~isscalar(y2), s3(i1) = y2(i1); end
  if any(i2) && ~isscalar(y1), s3(i2) = y1(i2); end
  
  try
    e3 = sqrt(genop(@plus, d1.^2,d2.^2));
    if any(i1), e3(i1) = e2(i1); end
    if any(i2), e3(i2) = e1(i2); end
  catch
    e3 = [];  % set to sqrt(Signal) (default)
  end
  
  if     all(m1==0), m3 = m2; 
  elseif all(m2==0), m3 = m1; 
  else
    try
      m3 = genop(@plus, m1, m2);
      if any(i1), m3(i1) = m2(i1); end
      if any(i2), m3(i2) = m1(i2); end
    catch
      m3 = [];  % set to 1 (default)
    end
  end
  
case {'times','rdivide', 'ldivide','mtimes','mrdivide','mldivide','mpower','conv','xcorr'}
  if strcmp(op, 'conv') || strcmp(op, 'xcorr')
    s3 = fconv(y1, y2, varargin{:});  % pass additional arguments to fconv
    if nargin == 4
      if strfind(varargin{1}, 'norm')
        m2 = 0;
      end
    end
  else
    s3 = genop(op, y1, y2);
  end
  
  try
    if all(s1(:)==0) e1s1=0; else e1s1 = genop(@rdivide,e1,s1).^2; e1s1(find(s1 == 0)) = 0; end
    if all(s2(:)==0) e2s2=0; else e2s2 = genop(@rdivide,e2,s2).^2; e2s2(find(s2 == 0)) = 0; end
    e3 = genop(@times, sqrt(genop(@plus, e1s1, e2s2)), s3);
  catch
    e3=[];  % set to sqrt(Signal) (default)
  end
  
  if     all(m1==0), m3 = m2; 
  elseif all(m2==0), m3 = m1; 
  elseif p1
    try
      m3 = genop(@times, m1, m2);
    catch
      m3 = [];  % set to 1 (default)
    end
  else m3=get(c,'Monitor'); end
  
case {'power'}
  s3 = genop(op, y1, y2);

  try
    e2logs1 = genop(@times, e2, log(s1)); e2logs1(find(s1<=0))   = 0;
    s2e1_s1 = genop(@times, s2, genop(@rdivide,e1,s1));  s2e1_s1(find(s1 == 0)) = 0;
    e3 = s3.*genop(@plus, s2e1_s1, e2logs1);
  catch
    e3 = [];  % set to sqrt(Signal) (default)
  end
  
  if     all(m1==0), m3 = m2; 
  elseif all(m2==0), m3 = m1; 
  elseif p1
    try
      m3 = genop(@times, m1, m2);
    catch
      m3 = [];  % set to 1 (default)
    end
  else m3=get(c,'Monitor'); end
  
case {'lt', 'gt', 'le', 'ge', 'ne', 'eq', 'and', 'or', 'xor', 'isequal'}
  s3 = genop(op, y1, y2);
  try
    e3 = sqrt(genop( op, d1.^2, d2.^2));
    e3 = 2*genop(@divide, e3, genop(@plus, y1, y2)); % normalize error to mean signal
  catch
    e3=0; % no error
  end
  m3 = 1; % set to 1 (default)
otherwise
  if isa(a,'iData'), al=a.Tag; else al=num2str(a); end
  if isa(b,'iData'), bl=b.Tag; else bl=num2str(b); end
  iData_private_error('binary',['Can not apply operation ' op ' on objects ' al ' and ' bl '.' ]);
end

% ensure that Monitor and Error have the right dimensions
if numel(e3) > 1 && numel(e3) ~= numel(s3)
  e3 = genop(@times, e3, ones(size(s3)));
end
if numel(m3) > 1 && numel(m3) ~= numel(s3)
  m3 = genop(@times, m3, ones(size(s3)));
end

% handle special case of operation with transposed 1D data set and an other one
if transpose_ab==1
  s3 = permute(s3,[ 2 1 3:length(size(s3)) ]);
  e3 = permute(e3,[ 2 1 3:length(size(e3)) ]);
  m3 = permute(m3,[ 2 1 3:length(size(m3)) ]);
end

% set Signal label
if isa(a, 'iData'), [dummy, al] = getaxis(a,'0'); 
else 
  al=num2str(a(:)'); if length(al) > 10, al=[ al(1:10) '...' ]; end 
end
if isa(b, 'iData'), [dummy, bl] = getaxis(b,'0'); 
else 
  bl=num2str(b(:)');
  if length(bl) > 10, bl=[ bl(1:10) '...' ]; end 
end

% operate with Signal/Monitor and Error/Monitor (back to Monitor data)
if not(all(m3(:) == 0 | m3(:) == 1)) & p1, 
  s3 = genop(@times, s3, m3); e3 = genop(@times,e3,m3); 
end

% update object (store result)
c  = set(c, 'Signal', s3);
y3 = get(c, 'Signal');
% test if we could update signal as expected, else we store the new value directly in the field
if sum(s3(~isnan(s3))) ~= sum(y3(~isnan(y3)))
  c = setalias(c, 'Signal', s3, [  op '(' al ',' bl ')' ]);
end
% for Error and Monitor, we do the same, except that these are set to scalars
% in setalias, so we directly set them in c.Alias.Values{2|3}
e3=abs(e3);
c  = set(c, 'Error', e3);
y3 = get(c, 'Error');
if sum(e3(~isnan(e3))) ~= sum(y3(~isnan(y3)))
  c.Alias.Values{2} = e3;
end
c  = set(c, 'Monitor', m3);
y3 = get(c, 'Monitor');
if sum(m3(~isnan(m3))) ~= sum(y3(~isnan(y3)))
  c.Alias.Values{3} = m3;
end

c.Command=cmd;
c = iData_private_history(c, op, a,b);

% reset warnings
iData_private_warning('exit',mfilename);
