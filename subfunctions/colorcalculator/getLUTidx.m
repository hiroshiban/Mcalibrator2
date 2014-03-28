function idx=getLUTidx(lut,rgb)

% Gets indices to the elements in Color LookUpTable that are closest to the input RGB values.
% function idx=getLUTidx(lut,rgb)
%
% a subfunction to handle data
% get LUT's index corresponding to the input RGB values
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2014-03-27 18:11:12 ban"

idx=zeros(size(rgb,2),3);
for nn=1:1:size(rgb,2), idx(nn,:)=ceil(((rgb(:,nn))'-lut(1,:))./(lut(end,:)-lut(1,:)).*size(lut,1)); end
idx(idx<=0)=1;
idx(idx>size(lut,1))=size(lut,1);

return
