function s = ones(iData_in,varargin)
% s = ones(s,N,M,P,...) : initialize an iData array
%
%   @iData/ones function to create an array of 's' iData objects
%   The object 's' is duplicated into an array. Use s=iData to get an empty array.
%
% input:  s: object or array (iData)
% output: b: object or array (iData)
% ex: ones(iData,5,5) will create a 5-by-5 empty iData array
%     ones(s,5,5) will return a 5-by-5 array filled with 's'
%
% Version: $Revision: 1035 $
% See also iData

% EF 27/07/00 creation
% EF 23/09/07 iData impementation

s = zeros(iData_in, varargin{:});

