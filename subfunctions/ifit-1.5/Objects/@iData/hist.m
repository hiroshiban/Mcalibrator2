function c=hist(a, varargin)
% hist(a, axis1, axis2, ...) computes the accumulated histogram from event data sets
%
%   @iData/hist function to compute the accumulated histogram from an event data
%     set. This is similar to a call to hist and accumarray.
%
%   hist(a, axis1, axis2, ...) specify the axes as bin edges. The axes 
%     should be vectors or a single value that indicates the number of bins in the
%     range [min, max] of the corresponding axis rank in the initial object. 
%     The bin edges vectors have length(a{k])+1 elements. A default of 33 bins 
%     is used when not specified.
%
%   hist(a, [ bin1 bin2 ...]) same as above when specifying the number of bins.
%
%   hist(a, ..., 'Fun', FUN) 
%     applies the function FUN to each subset of elements of VAL.  FUN is
%     a function that accepts a column vector and returns
%     a numeric, logical, or char scalar, or a scalar cell.  A has the same class
%     as the values returned by FUN.  FUN is @SUM by default.  Specify FUN as []
%     for the default behavior.
%
% input:  a: object or array (iData)
%         axis1, axis2, ...: bins or number of bins  (vector or scalar)
% output: c: histogrammed object (iData)
% ex:     a=iData([ ifitpath 'Data/Monitor_GV*']); b=hist(a);
%
% Version: $Revision: 1140 $
% See also iData, accumarray, hist, histc, iData/plot, sum, iData/interp

% private: histcn from % Bruno Luong: <brunoluong@yahoo.com> 25/August/2011

c=[];
% handle handle array as input
if numel(a) > 1
  c = zeros(iData, numel(a), 1);
  parfor index=1:numel(a)
    c(index) = hist(a(index), varargin{:});
  end
  return
end

if ~isvector(a), c=a; return; end

% scan varargin and search for AccumData
% add it if not specified
use_accumdata=0;
for index=1:length(varargin)
  if ischar(varargin{index})
    if strcmpi(varargin{index}, 'AccumData')
      use_accumdata=index;
      break
    end
  end
end

% check if varargin first argument is a bin vector
if length(varargin) && length(varargin{1}) == ndims(a)
  arg = cell(1,length(varargin)+ndims(a)-1);
  d   = varargin{1};
  for index=1:ndims(a)
    arg{index} = d(index);
  end
  for index=1:(length(varargin)-1)
    arg(ndims(a)+index) = varargin(index+1);
  end
  varargin = arg;
end

% is the Signal already specified in options (should not)
signal = get(a, 'Signal'); signal=signal(:);
if ~use_accumdata
  varargin{end+1} = 'AccumData';
  varargin{end+1} = signal;
  use_accumdata = length(varargin);
end

% build the matrix of events
use_axes= [];
axes    = [];
for index=1:ndims(a)
  ax = getaxis(a, index);
  if length(ax) == length(signal)
    axes = [ axes ax(:) ];
    use_axes= [ use_axes index ];
  end
end
clear ax signal
if isempty(use_axes), c=a; return; end

% now call the magic function (private)
[count edges] = histcn(axes, varargin{:});

% compute the Error and Monitor
e = subsref(a,struct('type','.','subs','Error'));
if  ~isempty(e) && not(all(e(:) == 0 | e(:) == 1))
  varargin{use_accumdata} = e.^2;
  count_e = histcn(axes, varargin{:});
  count_e = sqrt(count_e);
else
  count_e = e;
end

m = subsref(a,struct('type','.','subs','Monitor'));
if  ~isempty(m) && not(all(m(:) == 0 | m(:) == 1))
  varargin{use_accumdata} = m;
  count_m = histcn(axes, varargin{:});
else
  count_m = m;
end

% assemble final new object
c = copyobj(a);
c.Data=[];
c.Data.signal=count;
rmaxis(c); rmalias(c);

c = setalias(c, 'Signal','Data.signal');
c = setalias(c, 'Error',   count_e);
c = setalias(c, 'Monitor', count_m);

for index=1:length(edges)
  [link, lab] = getaxis(a, num2str(index));
  if isempty(link), continue; end
  if ~ischar(link), link=['Axis_' num2str(index)]; end
  c.Data.(link) = edges{index};
  c=setalias(c, link, [ 'Data.' link ], lab);
  c=setaxis(c, index, link);
end


% ------------------------------------------------------------------------------

function [count edges mid loc] = histcn(X, varargin)
% function [count edges mid loc] = histcn(X, edge1, edge2, ..., edgeN)
%
% Purpose: compute n-dimensional histogram
%
% INPUT
%   - X: is (M x N) array, represents M data points in R^N
%   - edgek: are the bin vectors on dimension k, k=1...N.
%     If it is a scalar (Nk), the bins will be the linear subdivision of
%     the data on the range [min(X(:,k)), max(X(:,k))] into Nk
%     sub-intervals
%     If it's empty, a default of 32 subdivions will be used
%
% OUTPUT
%   - count: n-dimensional array count of X on the bins, i.e.,
%         count(i1,i2,...,iN) = cardinal of X such that
%                  edge1(i1) <= X(:,i1) < edge1(i1)+1 and
%                       ...
%                  edgeN(iN) <= X(:,iN) < edgeN(iN)+1
%   - edges: (1 x N) cell, each provides the effective edges used in the
%     respective dimension
%   - mid: (1 x N) cell, provides the mid points of the cellpatch used in
%     the respective dimension
%   - loc: (M x N) array, index location of X in the bins. Points have out
%     of range coordinates will have zero at the corresponding dimension.
%
% DATA ACCUMULATE SYNTAX:
%   [ ... ] = histcn(..., 'AccumData', VAL);
%   where VAL is M x 1 array. Each VAL(k) corresponds to position X(k,:)
%   will be accumulated in the cell containing X. The accumulate result
%   is returned in COUNT.
%   NOTE: Calling without 'AccumData' is similar to having VAL = ones(M,1)
%
%   [ ... ] = histcn(..., 'AccumData', VAL, 'FUN', FUN);
%     applies the function FUN to each subset of elements of VAL.  FUN is
%     a function that accepts a column vector and returns
%     a numeric, logical, or char scalar, or a scalar cell.  A has the same class
%     as the values returned by FUN.  FUN is @SUM by default.  Specify FUN as []
%     for the default behavior.
%
% Usage examples:
%   M = 1e5;
%   N = 3;
%   X = randn(M,N);
%   [N edges mid loc] = histcn(X);
%   imagesc(mid{1:2},N(:,:,ceil(end/2)))
%
% % Compute the mean on rectangular patch from scattered data
%   DataSize = 1e5;
%   Lat = rand(1,DataSize)*180;
%   Lon = rand(1,DataSize)*360;
%   Data = randn(1,DataSize);
%   lat_edge = 0:1:180;
%   lon_edge = 0:1:360;
%   meanData = histcn([Lat(:) Lon(:)], lat_edge, lon_edge, 'AccumData', Data, 'Fun', @mean);
%
% See also: HIST, ACCUMARRAY
% 
% Bruno Luong: <brunoluong@yahoo.com>
% Last update: 25/August/2011

%  Copyright (c) 2009, Bruno Luong
%  All rights reserved.
%
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are
%  met:
%
%      * Redistributions of source code must retain the above copyright
%        notice, this list of conditions and the following disclaimer.
%      * Redistributions in binary form must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in
%        the documentation and/or other materials provided with the distribution
%
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%  POSSIBILITY OF SUCH DAMAGE.

if ndims(X)>2
    error('hist>histcn: X requires to be an (M x N) array of M points in R^N');
end
DEFAULT_NBINS = 32;

AccumData = [];
Fun       = {};
Mode      = 'Centers';

% Looks for optional parameters
k=1;
while k <= length(varargin)
    if strcmpi(varargin{k},'AccumData')
        AccumData = varargin{k+1}(:);
        varargin(k:(k+1))=[];
    elseif strcmpi(varargin{k},'Fun')
        Fun = varargin(k+1); % 1x1 cell
        varargin(k:(k+1))=[];
    else
      k=k+1;
    end
end

% Get the dimension
nd = size(X,2);
edges = varargin;
clear varargin;
if nd<length(edges)
    nd = length(edges); % wasting CPU time warranty
else
    edges((end+1):nd) = {DEFAULT_NBINS};
end

% Allocation of array loc: index location of X in the bins
loc = zeros(size(X));
sz  = zeros(1,nd);
% Loop in the dimension
parfor d=1:nd
    ed = edges{d};
    Xd = X(:,d);
    if isempty(ed)
        ed = DEFAULT_NBINS;
    end
    if isscalar(ed) % automatic linear subdivision
        ed = linspace(min(Xd),max(Xd),ed+1);  
    end
    edges{d} = ed;
    % Call histc on this dimension
    [dummy loc(:,d)] = histc(Xd, ed, 1);
    % Use sz(d) = length(ed); to create consistent number of bins
    sz(d) = length(ed)-1;
end % for-loop

% Clean
clear dummy ed

% This is needed for seldom points that hit the right border
sz = max([sz; max(loc,[],1)]);

% Compute the mid points
if nargout > 2
  mid = cellfun(@(e) 0.5*(e(1:end-1)+e(2:end)), edges, ...
              'UniformOutput', false);
end
          
% Count for points where all coordinates are falling in a corresponding
% bins
if nd==1
    sz = [sz 1]; % Matlab doesn't know what is one-dimensional array!
end

hasdata = all(loc>0, 2);
if ~isempty(AccumData)
    count = accumarray(loc(hasdata,:), AccumData(hasdata), sz, Fun{:});
else
    count = accumarray(loc(hasdata,:), 1, sz);
end

