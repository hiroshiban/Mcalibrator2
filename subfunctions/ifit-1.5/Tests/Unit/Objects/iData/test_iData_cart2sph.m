function result=test_iData_cart2sph

  a=iData(peaks);
  b=cart2sph(a);
  result = [ 'OK     ' mfilename ];
