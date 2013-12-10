function disp(s_in, name)
% disp(s) : display iData object (details)
%
%   @iData/disp function to display iData object details
%
% input:  s: object or array (iData) 
% ex:     'disp(iData)'
%
% Version: $Revision: 1165 $
% See also iData, iData/display, iData/get

% EF 27/07/00 creation
% EF 23/09/07 iData implementation

if nargin == 2 && ~isempty(name)
  iname = name;
elseif ~isempty(inputname(1))
  iname = inputname(1);
else
  iname = 'ans';
end

% removes warnings during disp
iData_private_warning('enter',mfilename);
 
if numel(s_in) > 1
  eval([ iname ' = s_in;' ])
  eval([ 'display(' iname ');' ]); % makes sure the variable name is sent to 'display'.
else
  if isdeployed || ~usejava('jvm'), id='iData';
  else           id='<a href="matlab:doc iData">iData</a>';
  end
  if isvector(s_in) > 1, id = [ id ' list/event']; end
  fprintf(1,'%s = %s %iD object of size [%s]:\n',iname, id, ndims(s_in), num2str(size(s_in)));
  m = get(s_in, 'Monitor'); m=m(:);
  s=struct(s_in);
  s=rmfield(s,'Alias');
  % print source with hyperlink
  T= s.Source;
  s=rmfield(s,'Source');
  if exist(T,'file')
    if length(T) > 70, Ts=[ T(1:60) '...' T((end-8):end) ]; else Ts=T; end
    T =[ '<a href="' T '">' Ts '</a>' ];
  end
  fprintf(1,'              Source: %s\n', T)
  
  % update title
  T   = s.Title; if ~ischar(T), T=char(T); end
  if ~isvector(T), T=transpose(T); T=T(:)'; end
  T   = regexprep(T,'\s+',' '); % remove duplicated spaces
  if length(T) > 69, T=[ T(1:60) '...' T((end-8):end) ]; end
  s.Title=T;
  if isnumeric(s.Date), s.Date=datestr(s.Date); end
  if isnumeric(s.ModificationDate), s.ModificationDate=datestr(s.ModificationDate); end
  disp(s)
  
  % display the Aliases ---------------------------------------------------
  disp('Object aliases:');
  disp('         [Name]                           [Value]   [Description]');
  for index=1:length(s_in.Alias.Names)
    v = s_in.Alias.Values{index};
    if isempty(v)
      if strcmp(s_in.Alias.Names{index}, 'Error'), v='[] i.e. sqrt(Signal)';
      elseif strcmp(s_in.Alias.Names{index}, 'Monitor'), v='1'; end
    end 
    label = s_in.Alias.Labels{index};
    if length(label) > 30, label = [label(1:28) '...' ]; end 
    if isnumeric(v) | islogical(v), 
      if length(size(v)) > 2, v=v(:); end
      if numel(v) > 20, v=v(1:18); end
      v = mat2str(v,5); 
      if length(v) > 32, v = [v(1:29) '...' ]; end 
    elseif ischar(v)
      this = s_in;
      vv = [];
      
      % attempt to evaluate char content
      if ~exist(v)
        try
          vv = eval(v);
        end
      end
      if isempty(vv)
        try
          vv = get(s_in, v);
        end
      end
      
      % add some more information from the content of the char field
      if ~isempty(vv)
        if numel(vv) > 2
          if isvector(vv), sz=sprintf(' length [%i]', numel(vv)); 
          else sz=sprintf(' size %s', mat2str(size(vv))); end
        else sz = []; end
        if isnumeric(vv), 
          if length(size(vv)) > 2, vv=vv(:); end
          if numel(vv) > 10, vv=vv(1:10); end
          vv = mat2str(vv,2); 
        end
        if ischar(vv)
          vv = vv(:)';
          if length(vv) > 20, vv = [vv(1:18) '...' ]; end
          label = [ label ' ''' vv '''' sz ];
        end
        
      end
      
      if length(v) > 32, v = [ '...' v((end-28):end) ]; end
    else 
      label = [ label ' (' class(v) ')' ];
      v=class2str('s',v,'no comments'); 
      if length(v) > 32, v = [v(1:29) '...' ]; end 
    end
    if strcmp(s_in.Alias.Names{index}, 'Format') && ~isdeployed
      if isempty(label) || strcmp(label, v), label='help about formats'; end
      label=[ '<a href="matlab:doc(iData,''Load'')">' label '</a>' ];
    end
    v = strtrim(v); v(~isstrprop(v,'print') | v=='\')=''; 
    label = strtrim(char(label)); label(~isstrprop(label,'print') | label=='\')=''; 
    fprintf(1,'%15s  %32s   %s', s_in.Alias.Names{index}, v, label);
    if strcmp(s_in.Alias.Names{index}, 'Signal') & length(s_in.Alias.Axis) == 0
      x      = getaxis(s_in, 0);  x=x(:);
      if length(x) == 1
        fprintf(1,' [%g]', x);
      else
        fprintf(1,' [%g:%g]', min(x), max(x));
      end
      if ~(all(m(:)==1) | all(m(:)==0))
        fprintf(1,' (per monitor)');
      end
    end
    fprintf(1, '\n');
  end
  
  % display the Signal and Axes -------------------------------------------
  disp('Object axes:');
  disp('[Rank]         [Value]  [Description]');
  for index=0:length(s_in.Alias.Axis)
    [v, l] = getaxis(s_in, num2str(index,2)); 
    if ~ischar(v)
      if numel(v) > 5, v=v(1:5); end
      v=mat2str(v);
      if length(v) > 12, v = [v(1:12) '...' ]; end 
    end
    if length(l) > 20, l = [l(1:18) '...' ]; end 
    X      = getaxis(s_in, index); x=X(:);
    if length(x) == 1
      minmaxstd = sprintf('[%g]', x);
    elseif isvector(X)
      minmaxstd = sprintf('[%g:%g] length [%i]', min(x), max(x),length(x));
    else
      minmaxstd = sprintf('[%g:%g] size %s', min(x), max(x),mat2str(size(X)));
    end
    if index==0
      if not(all(m==1 | m==0))
        minmaxstd=[ minmaxstd sprintf(' (per monitor=%g)', mean(m(:))) ];
      end
      minmaxstd=[ minmaxstd sprintf(' sum=%g', sum(iData_private_cleannaninf(x))) ];
    end
    if prod(size(s_in)) < 1e4
      try
        [s, f] = std(s_in, index);
        minmaxstd=[ minmaxstd sprintf(' <%g +/- %g>', f,s) ];
      end
    end
    fprintf(1,'%6i %15s  %s %s\n', index, v, l, minmaxstd);
  end
  %iData(s_in);
end

% reset warnings during disp
iData_private_warning('exit',mfilename);

