function out = openoff(filename)
%OPENOFF Open an OFF 3D ascii File, display it
%        and set the 'ans' variable to an iData object with its content

out = openstl(filename, 'OFF');

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end

