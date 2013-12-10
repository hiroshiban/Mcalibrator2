function a=load_lamp_IN4_dump(a,t)
% function a=load_lamp_IN4_dump(a)
%
% Returns an iData style dataset from a preprocessed LAMP data
% TOF channels=1st column
% angle=1st row
% load_lamp_IN4_dump(a,'transpose') handle transposed data set
%
% (Quick'n'Dirty writup for IN4 data, 20080408 PW)
%
% Version: $Revision: 1157 $
% See also: iData/load, iLoad, save, iData/saveas

% handle input iData arrays
if numel(a) > 1
  for index=1:numel(a)
    a(index) = feval(mfilename, a(index));
  end
  return
end

a=iData(a);
% Find proper labels for Signal and Axis

axes_fields=findfield(a,'Axes_');
setalias(a,'RAW',axes_fields{1});
siz=size(a.RAW);
tof=a.RAW(:,1);
ang=a.Data.Axes(1,:);
if nargin>1
  setalias(a,'TOF',ang,'TOF [channel]');         % TOF channels=1st row
  setalias(a,'theta',tof,'Angle [deg]');         % angle=1st column
  setalias(a,'Signal',[ axes_fields{1} '(:,2:end)' ]);  % link to RAW
  setaxis(a,2,'TOF');
  setaxis(a,1,'theta');
  a=a';
else
  setalias(a,'TOF',tof,'TOF [channel]');         % TOF channels=1st column
  setalias(a,'theta',ang,'Angle [deg]');         % angle=1st row
  setalias(a,'Signal',[ axes_fields{1} '(:,2:end)' ]);  % link to RAW
  setaxis(a,1,'TOF');
  setaxis(a,2,'theta');
end

