function d = display(s_in, name)
% d = display(s) : display iFunc object (from command line)
%
% @iFunc/display function to display iFunc object.
%   Used when no ';' sign follows a iFunc object in matlab.
% The return value may be catched as a string to display.  
%
% input:  s: object or array (iFunc) 
% output: d: string to display (char)
% ex:     'display(iFunc)' or 'iFunc'
%
% Version: $Revision: 1165 $
% See also iFunc, iFunc/disp, iFunc/get

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
if isdeployed || ~usejava('jvm'), id='iFunc';
else           id='<a href="matlab:doc iFunc">iFunc</a>';
end
if length(s_in) == 0
    d = [ d sprintf(' %s model: empty\n',id) ];
else
    if numel(s_in) == 1
      d = [ d sprintf(' %s %iD model:\n\n', id, ndims(s_in)) ];
    else
      d = [ d sprintf(' %s model:\n\n', id) ];
    end
    if numel(s_in) > 1
      d = [ d sprintf('Index ') ];
    end
    d = [ d sprintf('    [Tag] [Dim]                                [Model] [Parameters ''p'']\n') ];

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
      d = [ d sprintf('%3d ', s.Dimension) ];                   % size;
      t = '';

      u = s.Name; u(~isstrprop(u,'print'))=' '; u=strtrim(u); 
      if length(u) > 20, u = [ u(1:18) '.' ]; end
      t = [ t ' ' u ];
      
      if isa(s.Expression, 'function_handle')
        s.Expression = func2str(s.Expression);
      end
      s.Expression = char(s.Expression);
      if ~strcmp(s.Description, s.Expression) && ~strcmp(s.Name, u)
        u = s.Description; u(~isstrprop(u,'print'))=''; u=strtrim(u); if ~isvector(u), u=u'; end
        if length(u) > 10, u = [ u(1:9) '.' ]; end % Name/Description/Expression
        t = [ t ' ' u ];
      end
      
      
      if ~strcmp(s.Expression, u)
        u = s.Expression; u(~isstrprop(u,'print'))=' '; if ~isvector(u), u=u'; end
        if length(u) > 20, u = [ u(1:18) '..' ]; end
        t = [ t ' ' u ];
      end
      if length(t) > 40, t = [ t(1:37) '...'  ]; end
      d = [ d sprintf('%40s ', t) ];
      
      % now display parameters in compact form
      t = '';
      for p=1:length(s.Parameters)
        name = strtok(s.Parameters{p}); % make sure we only get the first word (not following comments)
        t = [ t sprintf('%s', name) ];
        val  = [];
        if ~isempty(s.ParameterValues)
          try
            val = s.ParameterValues(p);
          end
        end
        if ~isempty(val), t = [ t sprintf('=%g', val) ]; end
        t = [ t ' ' ];
      end
      if length(t) > 40, t = [ t(1:37) '...'  ]; end

      d = [ d sprintf('%s\n', t) ];
    end
end



if nargout == 0
  fprintf(1,d);
end

