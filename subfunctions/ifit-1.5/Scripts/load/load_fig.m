function a=load_fig(a0)
% function a=load_fig(a0)
%
% Returns an iData style dataset from a Matlab figure
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

if ~isa(a0,'iData')
  a = load(iData,a0,'fig');
  return
end

% handle input iData arrays
if numel(a0) > 1
  for index=1:numel(a0)
    a(index) = feval(mfilename, a0(index));
  end
  return
end

a = iData(a0.Data.Handle);
close(a0.Data.Handle);
