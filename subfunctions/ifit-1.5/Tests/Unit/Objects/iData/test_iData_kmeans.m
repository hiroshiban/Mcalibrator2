function result = test_iData_kmeans

  a = iData(peaks);
  k = 3;
  b = kmeans(a, k);
  
  if max(b) == k && min(b) == 1
    result = 1;
  else
    result = 0;
  end
