function frame = getframe(a, dim)
% frame = getframe(s, dim) : create an iData object thumbnail/frame matrix
%
%   @iData/getframe function to create iData frames/thumbnails.
%   Such thumbnails may be used to create icons on GUIs
%   Note: a figure will flicker on screen.
%
% input:  s:   object or array (iData)
%         dim: dimension of the thumbnail. When specified, the frame has no labels, ticks, ...
%              to serve as a thumbnail
%
% output: frame: frame/thumbnail
% ex:     f=getframe(a); image(f.cdata);
%
% Version: $Revision: 1106 $
% See also iData, iData/plot, getframe, image, imwrite

if nargin < 2, dim=0; end
if numel(a) > 1
  frame = cell(size(a));
  parfor index=1:numel(a)
    frame{index} = getframe(a(index), dim);
  end
  return
end

f=figure('menubar','none','toolbar','none');
% put window out of sight
p=get(f,'Position'); p(1:2) = [-1000 -1000];
set(f,'Position',p);
if dim
  % resample a with a coarse grid if needed
  need_resample=0;
  a_axes = cell(1,ndims(a));
  for index=1:ndims(a)
    s = size(a,index);  % loads object axes, or 1:end if not defined 
    if s > dim
      a_axes{index} = round(linspace(1,s,dim));
      need_resample = 1;
    else
      a_axes{index} = 1:s;
    end
  end
  % fast resampling only using indexes
  if need_resample
    S.type='()';
    S.subs=a_axes;
    a = subsref(a, S);
  end
end

% plot the data
plot(a); 
if ndims(a) <= 2, view(2); end
drawnow
if dim
  legend off;
  xlabel(''); ylabel(''); title('');
  set(gcf,'Position',[50,50,dim,dim]);
  set(gca,'xtick',[]);
  set(gca,'ytick',[]) ;
  axis tight;
end
% extract frame

% force figure to be 'oncreen'
movegui(f);
frame=getframe(f); 

delete(f);

