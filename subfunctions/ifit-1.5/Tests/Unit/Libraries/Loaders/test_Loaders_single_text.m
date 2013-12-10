function result = test_Loaders_single_text
  a = load(iData, [ ifitpath 'Data/ILL_IN6.dat' ]);
  config = iLoad('load config');
  
  if isa(a, 'iData') && isstruct(config)
    result = [ 'OK     ' mfilename ];
  else
    result = [ 'FAILED ' mfilename ];
  end
