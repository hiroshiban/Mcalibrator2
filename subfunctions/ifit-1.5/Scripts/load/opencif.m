function out = opencif(filename)
%OPENCIF Open a Crystallographic Information Format (CIF), display it
%        and set the 'ans' variable to an iData object with its content
%        (Required cif2hkl to have been compiled with gfortran, see Install page).

out = openstl(filename, 'CIF');

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
