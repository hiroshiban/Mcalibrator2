function s = read_yaml(filename)
% read_yaml(filename)
%
% read_yam Wrapper to directly read YAML files using the YAML class
% Input:  filename: yaml/json file (string)
% output: structure


s       = YAML.read(filename);

end

