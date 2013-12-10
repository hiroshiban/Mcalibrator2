function result=test_iData_save

  a=iData(peaks);
  formats={'m','mat','fig','ps','hdf4','jpg','tiff','hdf5','cdf','nc','edf','png',...
    'csv','svg','wrl','dat','ply','vtk', 'stl', 'off', 'x3d', 'fits', ...
    'yaml','xml','pdf','eps','mantid'};
  result = [ 'OK     ' mfilename ' (' num2str(length(formats)) ' formats)' ];
  failed = '';
  for index=1:length(formats)
    f=save(a, 'test', formats{index}); 
    if ~isempty(f)
        delete(f);
    else
        failed = [ failed ' ' formats{index} ];
    end
  end
  
  if ~isempty(failed)
    result = [ 'FAILED ' mfilename ' ' failed ];
  end
