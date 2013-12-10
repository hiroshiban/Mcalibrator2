function h=subplot(a, varargin)
% h = subplot(s) : plot iFunc array as subplots
%
%   @iFunc/subplot plot each iFunc model in a subplot
%     subplot(a, [])    uses the best subplot fit
%     subplot(a, [m n]) uses an m x n subplot grid
%
% input:  s: object or array (iData)
%         [m n]: optional subplot grid dimensions
% output: h: plot handles (double)
% ex:     subplot([ a a ])
%
% Version: $Revision: 1035 $
% See also iFunc, iFunc/plot

m=[]; n=[]; dim=[];

for index=1:length(varargin)
  if isa(varargin{index},'iFunc') 
    if numel(a) == 1
      a = [a ; varargin{index} ];
    else
      a = [a(:) ; varargin{index} ];
    end
  elseif isnumeric(varargin{index}), dim    = varargin{index};
  end
end
clear varargin
if numel(a) == 1
  h=plot(a);
  return
end

if length(dim) == 1 & dim(1) > 0
  m = dim; 
elseif length(dim) == 2, m=dim(1); n=dim(2); 
else m=[]; end
  
if any(m==0), m=[]; end
if isempty(m)
  if length(size(a)) == 2 & all(size(a) > 1)
    m = size(a,1); n = size(a,2);
  else
    p = numel(a);
    n = floor(sqrt(p));
    m = ceil(p/n);
  end
elseif isempty(n)
  n = ceil(length(a(:))/m);
end

h=[];

for index=1:numel(a)
  if ~isempty(a(index))
    subplot(m,n,index);
    this_h = plot(a(index));
    
    if length(a)> 12
      title(strtok(a(index).Name), 'interpreter','none');
      set(gca,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[])
    end
    h = [ h ; this_h(:) ];
  else h = [ h ; nan ];
  end
end

