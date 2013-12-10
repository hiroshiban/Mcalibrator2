function s = zeros(iData_in,varargin)
% s = zeros(s,N,M,P,...) : initialize an iData array
%
%   @iData/zeros function to create an array of 's' iData objects
%   The object 's' is duplicated into an array. Use s=iData to get an empty array.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex: zeros(iData,5,5) will create a 5-by-5 empty iData array
%     zeros(s,5,5) will return a 5-by-5 array filled with 's'
%
% Version: $Revision: 1035 $
% See also iData

% EF 27/07/00 creation
% EF 23/09/07 iData impementation

s = zeros(varargin{:});
if isempty(s), s=iData; return; end

s_index = 1;
long_s = iData_in(1);

for i = 2:numel(s)
  s_index = s_index +1;
  if s_index > numel(iData_in), s_index = 1; end
  long_s = [ long_s copyobj(iData_in(s_index)) ];
end

s = reshape(long_s, size(s));

