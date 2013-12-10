function out = openply(filename)
%OPENPLY Open an PLY 3D ascii File, display it
%        and set the 'ans' variable to an iData object with its content

out = openstl(filename, 'PLY');

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
