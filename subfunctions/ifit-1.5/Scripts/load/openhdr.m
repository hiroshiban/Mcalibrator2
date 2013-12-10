function out = openhdr(filename)
%OPENHDR Open a Analyze volume dataset (medical imaging), display it
%        and set the 'ans' variable to an iData object with its content

if ~isa(filename,'iData')
  out = iData(iLoad(filename,'Analyze'));
else
  out = filename;
end
clear filename;

if numel(out) > 1
  % handle input iData arrays
  for index=1:numel(out)
    out(index) = feval(mfilename, out(index));
  end
elseif isfield(out.Data,'hdr')
  % this is an Analyze HDR/IMG file. Proceed.
    
  hdr=out.Data.hdr;
  x = ([1:hdr.dim(1)]-hdr.origin(1))*hdr.siz(1);
  y = ([1:hdr.dim(2)]-hdr.origin(2))*hdr.siz(2);
  z = ([1:hdr.dim(3)]-hdr.origin(3))*hdr.siz(3);

  setalias(out,'Signal','Data.img');
  setalias(out,'x',x);
  setalias(out,'y',y);
  setalias(out,'z',z);
  setaxis(out,1,'x');
  setaxis(out,2,'y');
  setaxis(out,3,'z');
end

if ~nargout
  figure; subplot(out);
  
  if ~isdeployed
    assignin('base','ans',out);
    ans = out
  end
end

