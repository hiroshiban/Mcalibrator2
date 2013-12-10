function [filename,format] = saveas(a, varargin)
% f = saveas(s, filename, format, options) : save iFunc object into various data formats
%
%   @iFunc/saveas function to save models
%     This function saves the content of iFunc objects. The default format is 'm'.
%   saveas(iFunc,'formats')
%     prints a list of supported export formats.
%   saveas(iFunc,'file.ext')            determine file format from the extension
%   saveas(iFunc,'file','format')       sets file format explicitly
%     To load back a model from an m-file, type its file name at the prompt.
%     To load back a model from an mat-file, type 'load filename.mat' at the prompt.
%
% input:  s: object or array (iFunc)
%         filename: name of file to save to. Extension, if missing, is appended (char)
%                   If the filename already exists, the file is overwritten.
%                   If given as filename='gui', a file selector pops-up
%         format: data format to use (char), or determined from file name extension
%           'json' save as JSON JavaScript Object Notation, ascii
%           'm'    save as a flat Matlab .m file (a function which returns an iFunc object or structure)
%           'mat'  save as a '.mat' binary file (same as 'save', DEFAULT)
%           'yaml' save as YAML format, ascii
%         as well as other lossy formats
%           'fig'  save as a Matlab figure
%           'gif','bmp','png','tiff','jpeg','ps','pdf','ill','eps' save as an image
%           'hdf4' save as an HDF4 immage
%
%           'gui' when filename extension is not specified, a format list pops-up
%         options: specific format options, which are usually plot options
%           default is 'view2 axis tight'
%
% output: f: filename(s) used to save data (char)
% ex:     b=saveas(a, 'file', 'm');
%         b=saveas(a, 'file', 'gif', 'axis tight');
%
% Version: $Revision: 1084 $
% See also iFunc, save

% default options checks
if nargin < 2, filename = ''; else filename = varargin{1}; end
if isempty(filename), filename = [ 'iFit_' a.Tag ]; end
if nargin < 3, format=''; else format = varargin{2}; end
% if the filename is given only as an extension, use it as the format
if nargin == 2 && filename(1) == '.'
  format=filename(2:end);
  filename='';
end

if nargin < 4, options=''; else options=varargin{3}; end
if isempty(options) && any(ndims(a) >= 2), options='view2 axis tight'; end

% supported format list
filterspec = {...
      '*.dat', 'Flat text file with comments (*.dat)'; ...
      '*.eps', 'Encapsulated PostScrip (color, *.eps)'; ...
      '*.fig', 'Matlab figure (*.fig)'; ...
      '*.hdf4;*.h4', 'Hierarchical Data Format 4 image (*.hdf4)'; ...
      '*.jpg', 'JPEG image (*.jpg)'; ...
      '*.json', 'JSON JavaScript Object Notation (*.json)'; ...
      '*.m',   'Matlab script/function (*.m)'; ...
      '*.mat', 'Matlab binary file (*.mat)'; ...
      '*.pdf', 'Portable Document Format (*.pdf)'; ...
      '*.png', 'Portable Network Graphics image (*.png)'; ...
      '*.ps',  'PostScrip (color, *.ps)'; ...
      '*.tiff;*.tif', 'TIFF image (*.tif)'; ...
      '*.yaml;*.yml','YAML interchange format (*.yaml)' ...
};
if strcmp(filename, 'formats')
  fprintf(1, '       EXT  DESCRIPTION [%s(iFunc)]\n', mfilename);
  fprintf(1, '-----------------------------------------------------------------\n'); 
  for index=1:size(filterspec,1)
    ext = upper(filterspec{index,1});
    ext = strrep(ext,'.','');
    ext = strrep(ext,'*','');
    fprintf(1,'%10s  %s \n', ext, filterspec{index,2});
  end
  return
end

% filename='gui' pops-up a file selector
if strcmp(filename, 'gui')
  if numel(a) > 1, t=[ num2str(numel(a)) ' objects' ]; else t=get(a,'Name'); end
  [filename, pathname, filterindex] = uiputfile( ...
       filterspec, ...
        ['Save ' t ' as...'], a.Tag);
  if ~isempty(filename) & filename ~= 0
    ext = filterspec{filterindex,1};
    if iscellstr(ext), ext=ext{1}; end
    % check if extension was given
    [f,p,e] = fileparts(filename);
    if isempty(e), 
      filename=[ filename ext(2:end) ];
      format=ext(3:end);
    elseif isempty(format)
      format=e(2:end);
    end
  else
    filename=[]; return
  end
end

% format='gui' pops-up a list of available file formats, if not given from file extension
if any(regexp(format, '\<gui\>'))
  liststring= filterspec(:,2);
  format_index=listdlg('ListString',liststring,'Name',[ 'Select format to save ' filename ], ...
    'PromptString', {'Select format ',['to save file ' filename ]}, ...
    'ListSize', [300 200]);
  if isempty(format_index), return; end
  format = filterspec{format_index,1};
  format = format(3:end);
end

format=lower(strtrim(format));

% handle extensions
[path, name, ext] = fileparts(filename);
if isempty(ext) & ~isempty(format), 
  ext = [ '.' format ]; 
  filename = [ filename ext ];
elseif isempty(format) & ~isempty(ext)
  format = ext(2:end);
elseif isempty(format) & isempty(ext) 
  format='m'; filename = [ filename '.m' ];
end

% handle array of objects to save iteratively
if numel(a) > 1 & ~strcmp(lower(format),'mat')
  if length(varargin) >= 1, filename_base = varargin{1}; 
  else filename_base = ''; end
  if strcmp(filename_base, 'gui'), filename_base=''; end
  if isempty(filename_base), filename_base='iFunc'; end
  filename = cell(size(a));
  for index=1:numel(a)
    if numel(a) > 1
      [path, name, ext] = fileparts(filename_base);
      varargin{1} = [ path name '_' num2str(index,'%04d') ext ];
    end
    [filename{index}, format] = saveas(a(index), varargin{:});
  end
  return
end

% handle some format aliases (after extension extraction from file name)
switch format
case 'jpg'
  format='jpeg';
case 'eps'
  format='epsc';
case 'ps'
  format='psc';
case 'hdf'
  format='hdf4';
end

% remove NaN values, which are usually not well supported by text based formats

% ==============================================================================
% handle specific format actions
switch format
case 'm'  % single m-file Matlab output (text), with the full object description
  [dummy,e] = char(a); % get the model header
  e         = cellstr(e);
  a.Eval = '';
  NL = sprintf('\n');
  if ~isdeployed
    str = [ 'function this=' name NL ];
  else
    str = '';
  end
  str = [ str ...
          '% Original data: ' NL ...
          '%   class:    ' class(a) NL ...
          '%   variable: ' inputname(1) NL ...
          '%   tag:      ' a.Tag NL ...
          '%   name:    ' a.Name NL ...
          '%' NL ...
          '% Matlab ' version ' m-file ' filename ' saved on ' datestr(now) ' with iFunc/saveas' NL ...
          '% To use/import data, type ''' name ''' at the matlab prompt.' NL ...
          '% You will obtain an iFunc object (if you have iFunc installed) or a structure.' NL ...
          '%' NL ...
          NL ];
  [fid, message]=fopen(filename,'w+');
  if fid == -1
    iFunc_private_warning(mfilename,[ 'Error opening file ' filename ' to save object ' a.Tag 'in format ' format ]);
    disp(message)
    return
  end
  fprintf(fid, '%s', str);
  for index=1:length(e) % add the function header
    fprintf(fid, '%s\n', e{index});
  end
  fprintf(fid, '%s', class2str('this', a));
  fclose(fid);
  if isdeployed
    disp([ 'Warning: The standalone/deployed version of iFit does not allow to read back' NL ...
           '  function definitions. This m-file has been converted to a script that you can' NL ...
           '  import as "this" by typing: run ' filename ]);
  end
case 'dat'  % flat text file with commented blocks
  a.Eval = '';
  NL = sprintf('\n');
  str = [ '# Format: data with text headers' NL ...
          '# URL: ifit.mccode.org' NL ...
          '# Creator: iFit/@iFunc/saveas - ' version(a) NL ...
          '# Name: ' a.Name NL ...
          '# Tag: ' a.Tag NL ...
          '# ' NL ...
          class2str('', a, 'flat') ];
  [fid, message]=fopen(filename,'w+');
  if fid == -1
    iData_private_warning(mfilename,[ 'Error opening file ' filename ' to save object ' a.Tag 'in format ' format ]);
    disp(message)
    return
  end
  fprintf(fid, '%s', str);
  fclose(fid);
case 'mat'  % single mat-file Matlab output (binary), with the full object description
  if ~isempty(inputname(1))
    eval([ inputname(1) '= a;' ]);
    save(filename, inputname(1));
  else
    eval([ a.Tag '= a;' ]);
    save(filename, a.Tag);
  end
case 'epsc' % color encapsulated postscript file format, with TIFF preview
  f=figure('visible','off');
  plot(a,options);
  print(f, '-depsc', '-tiff', filename);
  close(f);
case {'png','tiff','jpeg','psc','pdf','ill','gif','bmp','pbm','pcx','pgm','pnm','ppm','ras','xwd','hdf4'}  % bitmap and vector graphics formats (PDF, ...)
  f=figure('visible','off');
  plot(a,options);
  print(f, [ '-d' format ], filename);
  close(f);
case 'fig'  % Matlab figure format
  f=figure('visible','off');
  plot(a,options);
  saveas(f, filename, 'fig');
  close(f);
case 'json'
  mat2json(struct(a), filename );    % in private
case {'yaml','yml'}
  YAML.write( filename, struct(a) ); % YAML object is in iFit/Objects
otherwise
  iFunc_private_warning(mfilename,[ 'Export of object ' inputname(1) ' ' a.Tag ' into format ' format ' is not supported. Ignoring.' ]);
  filename = [];
end

% end of iFunc/saveas


