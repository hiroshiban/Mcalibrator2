function out=openlaz(a, format)
%OPENLAZ Open a McStas Lazy HKL Powder file
%        display it and set the 'ans' variable to an iData object with its content
%        such files can be obtained from Crystallographica and ICSD <icsd.ill.fr>

if nargin < 2
  format = 'LAZ';
end

if ~isa(filename,'iData')
  out = iData(iLoad(filename,format));
else
  out = filename;
end
clear filename;

if numel(out) > 1
  % handle input iData arrays
  for index=1:numel(out)
    out(index) = feval(mfilename, out(index));
  end
elseif ~isempty(findstr(out,'Lazy')) || ~isempty(findstr(out,'Crystallographica'))

  % set HKL axes and Intensity signal. No Error.
  data_definition = getalias(out, 'Signal');
  columns_header = getfield(out.Attributes, fliplr(strtok(fliplr(data_definition),'.')));
  this = findstr(out,'VALUE');
  if ~isempty(this), this=this{1}; end
  % the header line may be split as it contains numerics. Prepend Attributes.VALUE.
  columns_header = [ this ' ' columns_header ];
  % the Lazy format has a column named 'D VALUE': remove the space so that columns are not shifted
  columns_header = strrep(columns_header, 'D VALUE','D_VALUE');
  columns = strread(columns_header,'%s','delimiter',' ;#');
  columns = columns(~cellfun('isempty', columns));
  for index=1:length(columns)
    % clean the column name so that it looks like a variable name
    columns{index} = strrep(columns{index}, '.','');
    columns{index} = strrep(columns{index}, '-','');
    columns{index} = strrep(columns{index}, '/','');
    columns{index} = strrep(columns{index}, '*','');
    columns{index} = strrep(columns{index}, '(','');
    columns{index} = strrep(columns{index}, ')','');
    columns{index} = genvarname(columns{index});
    if ~isfield(out, columns{index})
      setalias(out, columns{index}, [ data_definition '(:,' num2str(index) ')' ]);
      disp([ columns{index} '=' data_definition '(:,' num2str(index) ')' ]);
      this_axis = find(strcmpi(columns{index},{'h','k','l'}),1);
      if ~isempty(this_axis)
        this_axis = this_axis(1);
        setaxis(out, this_axis, columns{index}); 
      end
      this_axis=[];
      if   ~isempty(strfind(columns{index}, 'FHKL')) ...
        || ~isempty(strfind(columns{index}, 'Fsquared'))
        setaxis(out, 'Signal', columns{index});
      end
    end
  end

  setalias(out,'Error',0);
  out = transpose(out);
end

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
