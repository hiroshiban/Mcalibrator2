function result=test_iData_fileattrib

a=iData([ ifitpath 'Data/IRS21360_graphite002_ipg.nxs' ]);
a    = fileattrib(a, 'Signal',struct('an_attribure',42)); % add one
attr = fileattrib(a, 'Signal'); % get new attributes

if isstruct(attr) && attr.an_attribure == 42
  result = [ 'OK     ' mfilename ];
else
  result = [ 'FAILED ' mfilename ];
end
