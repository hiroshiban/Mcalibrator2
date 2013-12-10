function out = openhdf(filename, format)
%OPENHDF Open an HDF file, display it
%        and set the 'ans' variable to an iData object with its content

if nargin < 2
  format = 'HDF';
end

if ~isa(filename,'iData')
  out = iData(iLoad(filename,format));
else
  out = filename;
end
clear filename;

if numel(out) > 1
  % handle input iData arrays
  in = out;
  out = []; % the number of elements may change, can not simply replace
  for index=1:numel(in)
    out = [ out ; feval(mfilename, in(index)) ];
    in(index) = iData; % free memory
  end
  return
end

if ~isempty(findstr(out, 'NeXus')) || ~isempty(findfield(out, 'NX_class'))
  % special stuff for NeXus files
  out = load_NeXus(out); % see private
  
  % call other specific importers
  if ~isempty(findfield(out, 'RITA_2'))
    out = load_psi_RITA(out); % see private
  end
  
end % if Nexus
  
if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end

% ------------------------------------------------------------------------------

