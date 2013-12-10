function c_axis=iData_private_caxis(a, type)
% compute common axis for union and intersection

if nargin < 2,    type=''; end
if isempty(type), type='union'; end

c_axis=[];
if isempty(a), return; end

% determine largest dimensionality
max_ndims=max(ndims(a));
c_step=cell(max_ndims, 1); c_min=c_step; c_max=c_step; c_len=c_step;

% initiate new axes
parfor index=1:max_ndims
  c_step{index} =  Inf;
  if strcmp(type,'union') 
    c_min{index}  =  Inf;
    c_max{index}  = -Inf;
  else
    c_min{index}  = -Inf;
    c_max{index}  =  Inf;
  end
  c_len{index}  =  0;
end

% loop on all iData to find intersection area
for index=1:numel(a)
  if ndims(a(index)) ~= ndims(a(1))
    iData_private_warning(mfilename, [ 'Object ' type ' requires same dimensionality.\n\tobject ' inputname(1) ' ' a(1).Tag ' is ' num2str(ndims(a(1))) ' but object ' a(index).Tag ' is ' num2str(ndims(a(index))) '. Extending object.' ]);
  end
  parfor j_ax = 1:max_ndims  % for each dimension
    if j_ax <= ndims(a(index))
      x = getaxis(a(index), j_ax); x=unique(x(:));    % extract axis, and remove duplicates. diff > 0
      y = min(min(diff(x)), c_step{j_ax}); % smallest step
      if ~isempty(y), c_step{j_ax}=y; end  
      if strcmp(type,'union')  
        c_min{j_ax}  = min(min(x), c_min{j_ax});        % lowest min
        c_max{j_ax}  = max(max(x), c_max{j_ax});        % highest max
      else % intersection
        c_min{j_ax}  = max(min(x), c_min{j_ax});        % highest min
        c_max{j_ax}  = min(max(x), c_max{j_ax});        % lowest max
      end
      c_len{j_ax}  = c_len{j_ax} + length(x);         % cumulated axes length
    end
  end
end

% build new axes
for j_ax = 1:max_ndims  % for each dimension
  c_len{j_ax} = c_len{j_ax}/numel(a);                 % mean axis length from original data
  len         = (c_max{j_ax}-c_min{j_ax})/c_step{j_ax}; % theoretical axis length
  c_len{j_ax} = min(len+1, 2*c_len{j_ax});             % can not extend axes more than 10 times
  c_axis{j_ax}= linspace(c_min{j_ax}, c_max{j_ax}, c_len{j_ax});
end

