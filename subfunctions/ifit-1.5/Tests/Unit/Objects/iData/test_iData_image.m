function result=test_iData_image

  h=image(iData(peaks),[],[], 'hide axes');
  
  if ~isempty(h)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
