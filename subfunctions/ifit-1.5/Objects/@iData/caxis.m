function c = caxis(a, h)
% c = caxis(s, h) : Use the 2D/3D data as the colormap (CData property) in current object.
%
%   @iData/caxis function to use the current object as the colomap (CData).
%     The iData object is automatically rescaled in order to match the current 
%       surface/view axes.
%
% input:  s: object or array (iData)
%         h: surface or figure  (handle)
% output: c: graphics object handles that have been modified (handle array)
% ex:     a=iData(peaks); plot(a); caxis(del2(a));
%
% Version: $Revision: 1057 $
% See also iData, iData/plot

if nargin ==1
	h=gcf;
end
c=[];

% only one colormap/CData can be used
if numel(a) > 1
  iData_private_warning(mfilename, ['I can not handle iData arrays. ' inputname(1) ' size is [' num2str(size(a)) ']. Using first array element.']);
  a = a(1);
end

% handle handle array as input
if length(h) > 1
  c = zeros(size(h));
  parfor index=1:length(h)
    c(index) = caxis(a, h(index));
  end
  return
end

% get the list of children objects that have a CData property under 'h' handle
c = findall(h, 'Type', 'surface');

if isempty(c), return; end

parfor index=1:numel(c)
  % for each CData type object, interpolate the iData object onto the handle object axes
  x = get( c(index), 'XData'); % columns
  y = get( c(index), 'YData'); % rows
  z = get( c(index), 'ZData');
  if ndims(a) == 1
    % extend object so that it is a 2D one
    if isvector(x) & isvector(y)
      if size(a,1) == 1
        b = a.*ones(length(y), 1);
      else
        b = a.*ones(1, length(x));
      end
    else
      b = a .* ones(size(z));
    end
  else
    b = a;
  end
  s = double(b); % get Signal/Monitor
  s = interp2(1:size(s,2), 1:size(s,1), s, ...
       linspace(1,size(s,2),size(z,2)), linspace(1,size(s,1),size(z,1))' );
  set( c(index), 'CData', s);
end



