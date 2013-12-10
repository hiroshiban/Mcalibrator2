function s=iData_private_cleannaninf(s)
% iData_private_cleannaninf: clean NaNs and Infs from a numerical field
%

if isa(s,'iData')
  if numel(a) > 1
    s = [];
    for index=1:numel(a)
      s = [ s ; feval(mfilename, a(index)) ];
    end
  else
    s=set(s,'Signal',iData_private_cleannaninf(get(s,'Signal')));
    s=set(s,'Error', iData_private_cleannaninf(get(s,'Error')));
  end
  return
end
  
if isnumeric(s)
  S = s(:);
  if all(isfinite(S)), return; end
  index_ok     = find(isfinite(S));

  maxs = max(S(index_ok));
  mins = min(S(index_ok));

  S(isnan(S)) = 0;
  if ~isempty(mins)
    if mins<0, S(find(S == -Inf)) = mins*100;
    else       S(find(S == -Inf)) = mins/100; end
  end
  if ~isempty(maxs)
    if maxs>0, S(find(S == +Inf)) = maxs*100;
    else       S(find(S == +Inf)) = maxs/100; end
  end

  s = double(reshape(S, size(s)));
end
