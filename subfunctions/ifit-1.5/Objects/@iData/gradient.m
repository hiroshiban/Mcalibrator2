function b = gradient(a, dim)
% g = gradient(a, dim) : computes the gradient (derivative) of iData objects
%
%   @iData/gradient function to compute the gradient (derivative) of data sets.
%     the returned value is an iData array of the partials for dimension 
%     ranks 1,2,3..., that is g=[gy gx gz ...] (remember X is rank 2, Y is 1).
%     When the dimension is specified, only that rank partial derivative is returned.
%    
% input:  a: object or array (iData)
%       dim: dimension/rank of the partial to compute (int)
% output: g: object or cell array (iData)
% ex:     a=iData(peaks);
%         g=gradient(a); subplot([ a g(1) g(2) ]);
%
% Version: $Revision: 1041 $
% See also iData, iData/diff, iData/del2, diff, gradient, iData/jacobian

if nargin <= 1,
  dim = 0;
end

% handle input iData arrays
if numel(a) > 1
  b =cell(size(a));
  parfor index=1:numel(a)
    b{index} = feval(mfilename,a(index), dim);
  end
  return
end

if dim > ndims(a), b=[]; return; end

% make sure axes are regularly binned
a = interp(a);

% compute the gradient and return it in g (cell)
s = get(a, 'Signal'); % Signal
e = get(a, 'Error');
[dummy, sl] = getaxis(a, '0');

gs = cell(1,ndims(a)); ge=gs; gm=gs;
[gs{:}]=gradient(s);
if any(abs(e))
  [ge{:}] = gradient(e);
else ge = 0; 
end

% create returned object(s): one per dimension (axes)

cmd=a.Command;
b = [];
for i=1:ndims(s)
  % build each partial: beware index 1 and 2 are to swap
  index = i;
  if ndims(a) > 1
    if     i == 1, index=2;
    elseif i == 2, index=1;
    end
  end
  if dim && index ~= dim,  continue; end
  g = copyobj(a);
  g.Command=cmd;
  g = iData_private_history(g, mfilename, a, index);
  g = setalias(g, 'Error',  ge{index});
  g = setalias(g, 'Signal', gs{index}, [  mfilename '(' sl ',' num2str(index) ')' ]);
  b = [ b g ];
end

