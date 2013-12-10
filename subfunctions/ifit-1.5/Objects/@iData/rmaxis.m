function this = rmaxis(this,rank)
% s = rmaxis(s, Axis) : delete iData axes
%
%   @iData/rmaxis function to delete iData axes.
%     As Axes are often required for the Signal to be used, 
%     default axes will be automatically re-created when needed.
%   The Axis can be specified as a rank (1-ndims) or an axis name. 
%   When the Axis is empty, all axes are removed.
%   The input iData object is updated if no output argument is specified.
%   Axis 1 is often labelled as 'y' (rows, vertical), 2 as 'x' (columns, horizontal).
%
% input:  s: object or array (iData)
%         AxisIndex: rank or alias name of the axis
% output: s: array (iData)
% ex:     rmaxis(iData, 1) removes the 'x' axis (rank 1)
%
% Version: $Revision: 1158 $
% See also iData, iData/getaxis, iData/get, iData/set, iData/setaxis

% EF 27/07/00 creation
% EF 23/09/07 iData implementation
if nargin == 1
  rank = [];
end
% handle array of objects
if numel(this) > 1
  parfor index=1:numel(this)
    this(index) = rmaxis(this(index), rank);
  end
  if nargout == 0 & ~isempty(inputname(1))
    assignin('caller',inputname(1),this);
  end
  return
end

if isempty(rank)       % removes all axes
  this.Alias.Axis = {};
elseif isnumeric(rank) % removes some axes from their ranks
  rank = rank(find(rank > 0 & rank <= length(this.Alias.Axis)));
  this.Alias.Axis(rank) = '';
else                      % removes some axes from their alias definitions
  if ~iscell(rank)
    rank = { rank };
  end
  for index=1:numel(rank)
    rank = find(strcmp(rank, this.Alias.Axis));
    this.Alias.Axis(rank) = '';
  end
end

if nargout == 0 && ~isempty(inputname(1))
  assignin('caller',inputname(1),this);
end
