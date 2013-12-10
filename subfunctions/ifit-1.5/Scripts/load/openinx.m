function out = openinx(filename)
%OPENINX Open an INX tof data file, display it
%        and set the 'ans' variable to an iData object with its content

if ~isa(filename,'iData')
  out = iData(iLoad(filename,'ILL INX'));
else
  out = filename;
end
clear filename;

if numel(out) > 1
  % handle input iData arrays
  for index=1:numel(out)
    out(index) = feval(mfilename, out(index));
  end
elseif isfield(out, 'header') && isfield(out, 'Par') && isfield(out, 'Mat')
  % the data read with read_inx comes as:
  % s.Data.header: char
  % s.Data.Par:    double with parameters after the header/comment line
  % s.Data.Mat:    double
  Data = out.Data;
  Data.angle       = Data.Par(:,1);
  Data.wavelength  = Data.Par(:,2);
  Data.wavevector  = Data.Par(:,3);
  Data.temperature = Data.Par(:,4);
  Data.signal      = squeeze(Data.Mat(:,2,:));
  Data.error       = squeeze(Data.Mat(:,3,:));
  Data.energy      = squeeze(Data.Mat(:,1,:));
  Data.energy      = Data.energy(:,1);
  out.Data = Data; 
  clear Data

  setalias(out,'Signal', 'Data.signal', out.Data.header(2,:,1));
  setalias(out,'Error',  'Data.error');
  setalias(out,'Energy', 'Data.energy', ...
    [ 'Energy [meV] T=' num2str(mean(out.Data.temperature)) ' lambda=' num2str(mean(out.Data.wavelength)) ]);
  setalias(out,'Angle',       'Data.angle','Angle [deg]');
  setalias(out,'Wavelength',  'Data.wavelength','Wavelength [Angs]');
  setalias(out,'Wavevector',  'Data.wavevector','Wavevector [Angs]');
  setalias(out,'Temperature', 'Data.temperature','Sample Temperature [K]');

  if ndims(out) == 1
    setaxis(out, 1, 'Energy');
  elseif ndims(out) == 2
    setaxis(out, 1, 'Energy');
    setaxis(out, 2, 'Angle');
  end
  out.Title   =[ out.Data.header(2,:,1) ' ' out.Title ];

end

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end
