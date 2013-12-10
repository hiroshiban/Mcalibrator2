function result=test_iData_version

  if ischar(version(iData))
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
