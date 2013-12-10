function a = reshape(a, varargin)
% c = reshape(a) : reshape the object Signal
%
%   @iData/reshape function to reshape the object Signal array
%     reshape(a, m,n,p,...) reshapes the Signal as an m*n*p*... array
%       the number of elements in the initial Signal must be m*n*p*...
%     reshape(a, [m n p ...]) is the same thing.
%
%     the resulting object has the elements of the initial one reordered so that
%       the final size is that requested.
%
% input:  a:   object or array (iData)
%         m,n,p...: dimensions (integers)
% output: c: object or array (iData)
% ex:     a=iData(peaks); b=reshape(a, 10,90);
%
% Version: $Revision: 1035 $
% See also iData, iData/squeeze, iData/size, iData/permute, iData/resize

% first get dimensions from varargin
dims = [];
for index=1:length(varargin)
  dims = [ dims varargin{index} ];
end
if isempty(dims), return; end

% handle iData array: use built-in reshape
if numel(a) > 1
  a = builtin(mfilename, a, dims);
  return
end

% use reshape on Signal, Error, Monitor
sz = size(a);
if prod(sz) ~= prod(dims)
  iData_private_error(mfilename,[ 'To RESHAPE the number of elements must not change. Object ' ...
      a.Tag ' "' a.Title ' has dimension ' mat2str(size(a)) ' but requested to reshape into ' mat2str(dims) ]) ;
end
a  = iData_private_unary(a, 'reshape', dims(:)');

% then update axes
for index=1:length(dims)
  if length(sz) >= index && sz(index) ~= dims(index)
    x  = getaxis(a, index);
    if isvector(x), 
        x=x(:); sa = [length(x) 1]; 
        new_sa = [ dims(index) 1 ]; 
    else
        sa = size(x);
        new_sa = dims;
    end

    % resize axis if changed
    if ~isequal(sa, new_sa)
      x = iData_private_resize(x, new_sa);
      a = setaxis(a, index, x);
    end
  end
end

