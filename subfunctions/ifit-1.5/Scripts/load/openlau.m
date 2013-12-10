function out=openlau(a)
%OPENLAU Open a McStas Laue HKL file
%        display it and set the 'ans' variable to an iData object with its content
%        such files can be obtained from Crystallographica and ICSD <icsd.ill.fr>

out = openlaz(filename, 'LAU');

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
