function a = load_xyen(a)
% function a=load_xyen(a)
%
% Simple postprocessing for X Y E N files.
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

if ~isa(a,'iData')
  a = load(iData,a,mfilename);
  return
end

% handle input iData arrays
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index));
  end
  return
end

% special case for McStas files and XYEN (2-4 columns) files
n = size(a,2); % number of columns
if (ndims(a) == 2 && n >= 2 && n <= 4 && size(a,1) >= 5)
  if ~isempty(getaxis(a))
      xlab = label(a,1);
  else
      xlab = 'x [1st column]';
  end
  ylab = title(a);

  Datablock = ['this.' getalias(a,'Signal')];

  % First column is the scan parm, we denote that 'x'
  setalias(a,'x',      [Datablock '(:,1)'],xlab);
  setalias(a,'Signal', [Datablock '(:,2)'],ylab);
  if n>=3
    setalias(a,'Error',[Datablock '(:,3)']);
  else
    setalias(a,'Error',[]);
  end
  setalias(a,'E','Error');
  if ~isempty(findfield(a, 'Error')) || n >= 4
    setalias(a,'N',[Datablock '(:,4)'],'# Events');
  end
  setaxis(a,1,'x');
end
