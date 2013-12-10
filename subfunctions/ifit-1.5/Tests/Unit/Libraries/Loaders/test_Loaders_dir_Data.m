function result = test_Loaders_dir_Data

  tic;
  a = iLoad([ ifitpath 'Data' ]);
  toc
  if length(find(isempty(a))) > 3
    result = [ 'FAILED ' num2str(length(find(isempty(a)))-1) '/' num2str(length(a)) ];
  else
    result = [ 'OK     ' mfilename ' (' num2str(numel(a)) ' files)' ];
  end
