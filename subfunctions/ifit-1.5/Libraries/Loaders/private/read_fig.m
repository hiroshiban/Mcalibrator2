function s = read_fig(filename)
% mfigread Wrapper to directly read Matlab Figures

f       = openfig(filename, 'new','invisible');
s.Handle=f;

