% Kicks off both the Initialization script and the main function.

clearvars;
clc();
if exist('varInitialization', 'file') == 2
    delete Initialization.mat;
end
if exist('biMidrun', 'file') == 2
    delete afterrun.mat;
end
Initialization; % Loading required variables into workspace.
load varInitialization.mat;
main;