function idx=getLUTidx(lut,rgb)

% Gets indices to the elements in Color LookUpTable that are closest to the input RGB values.
% function idx=getLUTidx(lut,rgb)
%
% a subfunction to handle data
% get LUT's index corresponding to the input RGB values
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2013-12-11 17:22:15 ban"

idx=zeros(size(rgb,2),3);
for nn=1:1:size(rgb,2), idx(nn,:)=ceil((rgb(:,nn))'.*size(lut,1)); end
idx(idx<=0)=1;
idx(idx>size(lut,1))=size(lut,1);

return