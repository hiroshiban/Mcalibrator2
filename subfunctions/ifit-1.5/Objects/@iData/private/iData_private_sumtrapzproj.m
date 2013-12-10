function s = iData_private_sumtrapzproj(a,dim, op)
% s = iData_private_sumtrapzproj(a,dim, op) : computes the sum/trapz/camproj of iData objects elements
%
%   @iData/iData_private_sumtrapzproj function to compute the sum/trapz/camproj of the elements of the data set
%
% input:  a: object or array (iData/array of)
%         dim: dimension to accumulate (int/array of/'radial')
%         op: 'sum','trapz','camproj','prod'
% output: s: sum/trapz/camproj of elements (iData/scalar)
% ex:     c=iData_private_sumtrapzproj(a, dim, 'sum');
%
% Version: $Revision: 1158 $
% See also iData, iData/plus, iData/prod, iData/cumsum, iData/mean, iData/camproj, iData/trapz

% handle input iData arrays
if numel(a) > 1
  s = [];
  for index=1:numel(a)
    s = [ s feval(op, a(index), dim) ];
  end
  s = reshape(s, size(a));
  return
end

if isscalar(a)
  s = double(a);
  return
end

% removes warnings
iData_private_warning('enter',mfilename);

% some cases:
% signal is vector nD -> 

% in all cases except projection, resample the data set on a grid
% make axes single vectors for sum/trapz/... to work
if any(strcmp(op, {'sum','cumsum','prod','cumprod','trapz','cumtrapz'}))
  a = meshgrid(a, 'vector');
end

s = iData_private_cleannaninf(get(a,'Signal'));
e = iData_private_cleannaninf(get(a,'Error')); 
m = iData_private_cleannaninf(get(a,'Monitor'));

[link, label] = getalias(a, 'Signal');
cmd= a.Command;
b  = copyobj(a);

if any(dim == 0) && ~strcmp(op, 'sum')
  dim=1:ndims(a);
end

if all(dim > 0)
  % compute new object
  switch op
  case {'sum','cumsum'} % SUM ==================================================
    % sum on all dimensions requested
    e=e.^2;
    for index=1:numel(dim)
      if dim(index) == 1 && isvector(s)
        s = s(:); e=e(:); m=m(:);
      end
      if numel(e) > 1, e = feval(op, e, dim(index)); end
      if numel(m) > 1, m = feval(op, m, dim(index)); end
      s = feval(op, s, dim(index)); 
    end
    % Store Signal
    s=squeeze(s); e=sqrt(squeeze(e)); m=squeeze(m);
    setalias(b,'Signal', s, [op ' of ' label ' along axis ' num2str(dim) ]);
    
  case {'prod','cumprod'} % PROD ===============================================
    % product on all dimensions requested
    for index=1:numel(dim)
      if dim(index) == 1 && isvector(s)
        s = s(:); e=e(:); m=m(:);
      end
      if numel(e) > 1, e = feval(op, s+e/2, dim(index))-feval(op, s-e/2, dim(index)); end
      if numel(m) > 1, m = feval(op, m, dim(index)); end
      s = feval(op, s, dim(index)); 
    end
    % Store Signal
    s=squeeze(s); e=squeeze(e); m=squeeze(m);
    setalias(b,'Signal', s, [op ' of ' label ' along axis ' num2str(dim) ]);
    
  case {'trapz','cumtrapz'} % TRAPZ ============================================
    e=e.^2;

    for index=1:numel(dim)
      [x, xlab]     = getaxis(a,dim(index)); x=x(:);
      if dim(index) ~= 1  % we put the dimension to integrate on as first
        perm=1:ndims(a);
        perm(dim(index))=1; perm(1)=dim(index);
        s = permute(s, perm);
        e = permute(e, perm); 
        m = permute(m, perm);
      elseif isvector(s)
        s = s(:); x=x(:); e=e(:); m=m(:);
      end
      % make the integration
      if ~isscalar(s)
        if numel(e) > 1, e = feval(op, x, e, 1); end
        if numel(m) > 1, m = feval(op, x, m, 1); end
        s = feval(op, x, double(s), 1);
        if dim(index) ~= 1  % restore initial axes
          s = permute(s,perm);
          e = permute(e,perm);
          m = permute(m,perm);
        end
      end
    end
    % Store Signal
    s=squeeze(s); e=sqrt(squeeze(e)); m=squeeze(m);
    setalias(b,'Signal', s, [ op ' of ' label ' along ' xlab ]); 
    
  case 'camproj' % camproj =====================================================
    % accumulates on all axes except the rank specified
    [x, xlab]     = getaxis(a,dim);
    s             = subsref(a,struct('type','.','subs','Signal')); 
    if isvector(s),   lx=length(s); else 
      lx=size(s, dim); 
      if isvector(x)
        % replicate X along other axes
        sz = size(s); sz(dim) = 1;
        x = repmat(x, sz);
      end
    end
    rmaxis(b);
    setaxis(b, 1, x(:));
    % Store Signal
    setalias(b,'Signal', s(:), [ 'projection of ' label ' on axis ' num2str(dim) ]);     % Store Signal
    b = set(b, 'Error', abs(e(:)), 'Monitor', m(:));
    b = hist(b, lx); % faster than doing sum on each dimension

  end % switch (op, compute)
	
  if any(strcmp(op, {'sum','trapz','prod'}))
	% store new object
	b = set(b, 'Error', abs(e), 'Monitor', m);

    rmaxis(b);  % remove all axes, will be rebuilt after operation
    % put back initial axes, except those integrated
    ax_index=1;
    for index=1:ndims(a)
      if all(dim ~= index)
        [x, xlab] = getaxis(a, num2str(index)); % get axis definition and label
        setaxis(b, ax_index, x);
        ax_index = ax_index+1;
      end
    end
  end
	
elseif dim == 0
  s = sum(s(:));
  s = double(s);
  return  % scalar
end
b.Command=cmd;
b = iData_private_history(b, op, b, dim);
s = b;

if isscalar(s), s=double(s); end

% reset warnings
iData_private_warning('exit',mfilename);

