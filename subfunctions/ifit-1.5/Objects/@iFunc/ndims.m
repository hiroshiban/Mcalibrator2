function v=ndims(s)
% d = ndims(s) : get the dimensionality of iFunc object
%
%   @iFunc/ndims function to get the number of dimensions of the iFunc model.
%
% input:  s: object or array (iFunc)
% output: dimensionality of model in the object (double array)
% ex :    ndims(iFunc)
%
% Version: $Revision: 1035 $

if numel(s) > 1
  v = zeros(size(s)); 
  for index=1:numel(s)
    v(index) =ndims(s(index));
  end
  return
end

v = s.Dimension;


