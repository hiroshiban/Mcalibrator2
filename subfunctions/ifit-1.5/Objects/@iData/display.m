function d = display(s_in, name)
% d = display(s) : display iData object (from command line)
%
% @iData/display function to display iData object.
%   Used when no ';' sign follows a iData object in matlab.
% The return value may be catched as a string to display.  
%
% input:  s: object or array (iData) 
% output: d: string to display (char)
% ex:     'display(iData)' or 'iData'
%
% Version: $Revision: 1165 $
% See also iData, iData/disp, iData/get

% EF 27/07/00 creation
% EF 23/09/07 iData implementation

if nargin == 2 && ~isempty(name)
  iname = name;
elseif ~isempty(inputname(1))
  iname = inputname(1);
else
  iname = 'ans';
end

d = [ sprintf('%s = ',iname) ];

if numel(s_in) > 1
  d = [ d sprintf(' array [%s]',num2str(size(s_in))) ];
end
if isdeployed || ~usejava('jvm'), id='iData';
else           id='<a href="matlab:doc iData">iData</a>';
end
if isvector(s_in) > 1, id = [ id ' list/event']; end
if length(s_in) == 0
  d = [ d sprintf(' %s object: empty\n',id) ];
else
  if numel(s_in) == 1
    d = [ d sprintf(' %s %iD object:\n\n', id, ndims(s_in)) ];
  else
    d = [ d sprintf(' %s object:\n\n', id) ];
  end
  if numel(s_in) > 1
    d = [ d sprintf('Index ') ];
  end
  d = [ d sprintf('    [Tag] [Dimension]                                     [Title] [Last command]') ];
  if numel(s_in) > 1
    if any(~cellfun('isempty', get(s_in,'Label'))) || any(~cellfun('isempty', get(s_in,'DisplayName')))
      d = [ d '          [Label/DisplayName]' ];
    end
  else
    if ~isempty(get(s_in,'Label')) || ~isempty( get(s_in,'DisplayName'))
      d = [ d '          [Label/DisplayName]' ];
    end
  end
  d = [ d sprintf('\n') ];

  % now build the output string
  for index=1:numel(s_in)
    s = s_in(index);
    if length(s_in) > 1
      d = [ d sprintf('%5i ',index) ];                        % index
    end
    if isempty(s.Tag)
      d = [ d sprintf('%9s ','<nul>') ];                      % Tag
    else
      d = [ d sprintf('%9s ',s.Tag) ];
    end
    d = [ d sprintf('%11s ', [ mat2str(size(s)) ]) ];  % size
    t = cellstr(s.Title); t = strtrim(t{1}); t(~isstrprop(t,'print') | t=='\' | t=='%')=''; 
    if length(t) > 31, t = [ t(1:27) '...' ]; end             % object.title
    t = [ t ' "' title(s) '"' ]; t = strtrim(t); t(~isstrprop(t,'print') | t=='\')=''; 
    if length(t) > 41, t = [ t(1:37) '..."'  ]; end           % title(Signal)
    d = [ d sprintf('%43s ', [ '''' t '''' ]) ];
    h = cellstr(s.Command); h = strtrim(h{end}); h(~isstrprop(h,'print') | h=='\')=''; 
    if length(h) > 23, h = [ h(1:20) '...' ]; end             % last command
    d = [ d sprintf('%s ', h) ];
    if ~isempty(s.Label) && ~isempty(s.DisplayName)
      h = cellstr(s.Label); h = strtrim(h{1}); h(~isstrprop(h,'print') | h=='\')=''; 
      if length(h) > 13, h = [ h(1:10) ]; end                 % Label/DisplayName
      d = [ d sprintf('%s', h) ];
      h = cellstr(s.DisplayName); h = strtrim(h{1}); h(~isstrprop(h,'print') | h=='\')=''; 
      if length(h) > 13, h = [ h(1:10) '...' ]; end           % 
      d = [ d sprintf('/%s', h) ];
    elseif ~isempty(s.Label)
      h = cellstr(s.Label); h = strtrim(h{1}); h(~isstrprop(h,'print') | h=='\')=''; 
      if length(h) > 18, h = [ h(1:15) '...' ]; end           % Label
      d = [ d sprintf('%s', h) ];
    elseif ~isempty(s.DisplayName)
      h = cellstr(s.DisplayName); h = strtrim(h{1}); h(~isstrprop(h,'print') | h=='\')=''; 
      if length(h) > 18, h = [ h(1:15) '...' ]; end           % DisplayName
      d = [ d sprintf('%s', h) ];
    end

    d = [ d sprintf('\n') ];
    
  end
end

if nargout == 0
  fprintf(1,d);
end

