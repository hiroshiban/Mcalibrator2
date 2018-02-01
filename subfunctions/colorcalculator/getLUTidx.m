function [idx,argb]=getLUTidx(lut,rgb)

% Returns the Color LookUpTble indices for the required RGB values, together with the adjusted RGB values.
% function [idx,argb]=getLUTidx(lut,rgb)
%
% a subfunction to handle data
% gets LUT's index and the adjusted (linearized) RGB values corresponding to the input RGB values
%
% [input]
% lut : color lookup table, [LUT_length x 3 (RGB) x 2 (video inputs and luminance)]
% rgb : RGB video input values you want, [3 (RGB) x N]
%
% [output]
% idx : the indices to the ColorLookUpTable, [N x 3 (RGB)]
% argb: the adjusted (linearized) RGB values, [3 (RGB) x N]
%
%
% Created    : "2012-05-29 04:09:02 ban"
% Last Update: "2014-04-17 13:26:57 ban"

idx=zeros(size(rgb,2),3);
argb=zeros(3,size(rgb,2));

% case 1: the simplest transformation (but have to approximate the generated LUTs so that RGB=LUT(x) and LUT(0)=0)
%for nn=1:1:size(rgb,2), idx(nn,:)=ceil(rgb(:,nn)'.*size(lut,1)); end
%idx(idx<1)=1; idx(idx>size(lut,1))=size(lut,1);
%for ii=1:1:size(idx,1), argb(:,ii)=[lut(idx(ii,1),1,1); lut(idx(ii,2),2,1); lut(idx(ii,3),3,1)]; end

% case 2: a modified version of the transformation --- it can handle the case like RGB=LUT(x)+b and LUT(0)~=0)
xx=lut(1,:,2)./(lut(end,:,2)-lut(1,:,2));
for nn=1:1:size(rgb,2), idx(nn,:)=ceil( ((1+xx).*rgb(:,nn)'-xx).*size(lut,1) ); end
idx(idx<1)=1; idx(idx>size(lut,1))=size(lut,1);
for ii=1:1:size(idx,1), argb(:,ii)=[lut(idx(ii,1),1,1); lut(idx(ii,2),2,1); lut(idx(ii,3),3,1)]; end

return
