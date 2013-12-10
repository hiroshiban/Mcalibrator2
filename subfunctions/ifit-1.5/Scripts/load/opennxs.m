function out = opennxs(filename)
%OPENNXS Open a NeXus/HDF file, display it
%        and set the 'ans' variable to an iData object with its content

out = openhdf(filename);

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
