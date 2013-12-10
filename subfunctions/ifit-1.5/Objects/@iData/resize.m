function b = resize(a, varargin)
% c = resize(a) : resize/rebin the object Signal
%
%   @iData/resize function to resize/rebin the object Signal array
%     resize(a, m,n,p,...) resizes the Signal as an m*n*p*... array
%       using a N-D discrete cosine transform.
%     resize(a, [m n p ...]) is the same thing.
%
% input:  a:   object or array (iData)
%         m,n,p...: dimensions (integers)
% output: c: object or array (iData)
% ex:     a=iData(peaks); b=resize(a, 10,90);
%
% Version: $Revision: 1035 $
% See also iData, iData/squeeze, iData/size, iData/permute, iData/reshape

% first get dimensions from varargin
dims = [];
for index=1:length(varargin)
  dims = [ dims varargin{index} ];
end
if isempty(dims), return; end

% handle iData array: use built-in reshape
if numel(a) > 1
  b = builtin(mfilename, a, dims);
  return
end

% use reshape on Signal, Error, Monitor
sz = size(a);
b  = iData_private_unary(copyobj(a), 'iData_private_resize', dims);

% then update axes
for index=1:length(dims)
  if length(sz) >= index && sz(index) ~= dims(index)
    x  = getaxis(a, index);
    if isvector(x), x=x(:); sa = [length(x) 1]; else sa = size(x); end
    
    if ~isvector(x), new_sa = dims; 
    else             new_sa = [ dims(index) 1]; end

    % resize axis if changed
    if ~isequal(sa, new_sa)
      x = iData_private_resize(x, new_sa);
      b = setaxis(b, index, x);
    end
  end
end

