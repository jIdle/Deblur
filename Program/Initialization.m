% Initializing variables
AXIS = [2  298  2  298];    % User selected patch.
szBlurKernel = 35;          % Size of blur in pixels.
fBlurMode = 'hbar';         % Switch to hbar/vbar if needed.
activeImg = imread('C:\Program Files\MATLAB\R2018a\Projects\My_Project\Blurred_Images\street_lamp.jpg');  
scaleFactor = 1;            % If the picture is to big use this to scale it down.
LR_Iterations = 10;         % This controls the number of Lucy-Richardson deconvolution iterations.
priorType = 'street';       % Switch to 'street'/'whiteboard' if needed.
kernelScales = ceil(-log(3/szBlurKernel) / log(sqrt(2)))+1; % Number of upsampled blur kernels.
pRange = [AXIS(2)-AXIS(1) AXIS(4)-AXIS(3)];                 % pRange and pCoord are the patch boundaries.
pCoord = [AXIS(1) AXIS(3)];
load(priorType);                    % Loading image prior data into workspace.
if mod(szBlurKernel, 2) == 0        % Changing to odd kernel size.
    szBlurKernel = szBlurKernel + 1;
end
blurKernel = zeros(szBlurKernel);
tempDim = floor(szBlurKernel/2) + 1;
blurKernel(tempDim, tempDim) = 1; 
nmFile = strcat('var', mfilename);  % Name of current file
save(nmFile);