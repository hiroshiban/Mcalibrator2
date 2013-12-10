function out = openstl(filename, format)
%OPENSTL Open an STL/SLP 3D ascii stereolithography data file, display it
%        and set the 'ans' variable to an iData object with its content

if nargin < 2
  format = 'STL';
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
else
  % this may be an OFF/PLY/CFL/STL file. Proceed.
    
  out = load_stl(out); % see private
end

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end

