function d = doc(a, page)
% doc(iFunc): iFunc web page documentation
%
%   @iFunc/doc: web page documentation
%
%     Open the iFunc documentation.
%     doc(iFunc,page) opens a specific documentation page
%
%     doc(iFunc,'Load')
%     doc(iFunc,'Save')
%     doc(iFunc,'Math')
%     doc(iFunc,'Fit')
%     doc(iFunc,'Plot')
%     doc(iFunc,'Methods')
%
% Version: $Revision: 1035 $

% EF 23/10/10 iFunc impementation
if nargin ==1, page=''; end
if isempty(page), page='iFunc.html'; end
doc(iData, page);
