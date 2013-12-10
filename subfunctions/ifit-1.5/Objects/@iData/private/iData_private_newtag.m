function b = iData_private_newtag(a)
% Data_private_newtag: assigns a new tag and creation date to iData object

persistent id

b = a;
b.Date = clock;  % new object

% create new tag
% if ~exist('id'),  id=0; end
if isempty(id),   id=0; end
if id > 1e6, id=0; end
if id <=0, 
  id = b.Date;
  id = fix(id(6)*1e4); 
else 
  id=id+1;
end

b.Tag      = [ 'iD' sprintf('%0.f', id) ];
      
if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),b);
end
