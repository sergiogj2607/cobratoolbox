function environment = getEnvironment()
% Get all values of current globals in a struct.
% USAGE:
%    environment = getEnvironment()
%
% OUTPUT:
%
%    environment:      a struct with two fields
%                       * .globals - contains all global values
%                       * .path - contains the current path
environment = struct();
globals = struct();
globalvars = who('global');
for i = 1:numel(globalvars)
    globals.(globalvars{i}) = getGlobalValue(globalvars{i});
end
environment.globals = globals;
environment.path = path;
end


function value = getGlobalValue(globalName)
% Safely get the Value of a global variable.
%
% USAGE:
%    getGlobalValue(globalName)
%
% INPUTS:
%    globalName:    The name of the global variable to get the value for

    eval(['global ' globalName]);
    eval(['value = ' globalName ';']);
end