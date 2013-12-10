function result=test_iData_colormap

  a=iData(peaks);
  h = colormap(a,jet,a+10,hsv,'log transparent');
  
  if ~isempty(h)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
