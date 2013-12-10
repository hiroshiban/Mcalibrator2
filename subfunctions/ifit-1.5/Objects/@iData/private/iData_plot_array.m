function h = iData_plot_array(a, method, this_method)
% iData_plot_array: plot an array of iData objects
% used in iData/plot

sum_max = 0;
  % plot objects in the same axis frame
  % set error bar uniformly along objects
  common_error_bar='undefined'; % will set the value to 0/1 when 1D found
  for index=1:numel(a(:))
    if isempty(a(index)), h{index} = []; continue; end
    if ndims(a(index)) == 1 && isvector(a(index)) == 1 && ...
      isempty(getaxis(a(index),2)) && ...
      (~isempty(strfind(method, 'plot3'))      || ~isempty(strfind(method, 'stem')) ...
       || ~isempty(strfind(method,'scatter'))  || ~isempty(strfind(method, 'mesh')) ...
       || ~isempty(strfind(method,'surf') )    || ~isempty(strfind(method, 'waterfall')))
      a(index) = setaxis(a(index), 2, index);
    end
    h{index} = plot(a(index), method);
    if ndims(a(index)) == 1
      if length(h{index}) == 1 && length(get(h{index},'Children') == 2)
        eh = get(h{index},'Children');
      else eh = h{index}; 
      end
      if length(eh) > 1
        if strcmp(common_error_bar, 'undefined')
          common_error_bar = get(eh(2), 'Visible');
        else
          set(eh(2), 'Visible',common_error_bar);
        end
      end
    end
    s = getaxis(a(index), 0);
    sum_max = sum_max+max(s(:))-min(s(:));
    this_h = get(h{index},'Type'); if iscell(this_h), this_h=this_h{1}; end
    % do we specify a color ? if none, we will circulate colors along array elements
    if any(strcmp(this_h,{'line','hggroup'})) % we have drawn lines
      if ~any(this_method == 'b' | this_method == 'g' | this_method == 'r' | this_method == 'c' | this_method == 'm' | this_method == 'k')
        this_method = '';
      end
      if isempty(this_method) && isempty(strfind(method,'scatter'))
        % change color of line
        colors = 'bgrcmk';
        set(h{index}, 'color', colors(1+mod(index, length(colors))));
      end
    end
    hold on
  end % for
  
  % re-arrange if this is a 2D overlay (shifted)
  if all(cellfun('length',h) <= 1)
    h = cell2mat(h);
  end
  for index=1:numel(h)
    if length(h(index)) == 1 && ~isempty(strfind(method, 'shifted'))
      if ndims(a(index)) ~= 1
        try
          z= get(h(index),'ZData'); 
          c= get(h(index),'CData');
          if all(z(:) == 0)
               use_cdata=1; z= c;
          else use_cdata=0; 
          clear c
          end
          z = z-min(z(:));
          z = z+sum_max*index/numel(a);
          if use_cdata==0, 
               set(h(index),'ZData',z);
          else set(h(index),'CData',z); 
          end
        end
      else
        try
          z= get(h(index),'YData');
          z = z-min(z(:));
          z = z+sum_max*index/length(a(:));
          set(h(index),'YData',z); 
        end
      end
    end
  end
