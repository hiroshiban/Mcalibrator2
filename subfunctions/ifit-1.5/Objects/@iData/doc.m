function url = doc(a, page)
% doc(iData): iData web page documentation
%
%   @iData/doc: web page documentation
%
%     Open the iData documentation.
%     doc(iData,page) opens a specific documentation page
%
%     doc(iData,'Load')
%     doc(iData,'Save')
%     doc(iData,'Math')
%     doc(iData,'Fit')
%     doc(iData,'Plot')
%     doc(iData,'Methods')
%
% Version: $Revision: 1035 $

% EF 23/10/10 iData impementation
if nargin ==1, page=''; end
if isempty(page), page='index.html'; end
[p,f,e] = fileparts(page);
if isempty(e), e='.html'; end
page = [ f e ];

url = [ ifitpath filesep 'Docs' filesep page ];
if ~isempty(dir(url)) % page exists ?
  disp(version(iData))
  disp('Opening iData documentation from ')
  if length(url) && ~isdeployed && usejava('jvm')
    disp([ '  <a href="matlab:web ' url '">web ' url '</a>' ]);
  else
    disp([ '  ' url ]);
  end
  web(url);
end

