function out = opennc(filename)
%OPENNC Open a NetCDF file, display it
%        and set the 'ans' variable to an iData object with its content

out = opencdf(filename);

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
