function out = openhdf5(filename)
%OPENHDF5 Open an HDF5 file, display it
%        and set the 'ans' variable to an iData object with its content

out = openhdf(filename, 'HDF5');

if ~isdeployed
  assignin('base','ans',out);
  ans = out
end
