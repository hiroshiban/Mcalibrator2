function s = read_fits(filename)
% mfitsread Wrapper to fitsinfo/fitsread which reconstructs the FITS structure

s      = fitsinfo(filename);
s.data = fitsread(filename);

