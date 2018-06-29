% Kobe Davis
% CS 510
% 10 June 2018
%
% This program's purpose is to deblur an image blurred by camera shake. 
% The settings to configure the program are in Initialization.m.
% KickStart.m is the script used to start the program.
%
% Before KickStart can be used to start the program a few things must be
% done:
%
% 1. The MATLAB path must be set appropriately so that MATLAB has access to
% the image you are trying to deblur, the function and script files for the
% program and the image files.
%
% 2. In Initialization.m, activeImg must be set to
% the image path in your directory.
%
% 3. In Initialization.m, priorType must be set to
% either 'street' or 'whiteboard' for the inference's first iteration.
%
% 4. In Initialization.m, AXIS must be set to the user selected patch on 
% the blurred image.
%
% 5. In Initialization.m, szBlurKernel must be set to the estimated blur
% "size". The best way to do this is simply to use the MATLAB "figure" to
% get a closer look at the number of pixels the blur covers.
%
% 6. In Initialization.m, fBlurMode must be set to either vbar or hbar.
% Both represent the starting configuration of the 3x3 blur kernel right
% before the bayesian inferencing process. vbar is just a vertical bar
% in the 3x3 blur kernel and hbar represents a horizontal bar in the 3x3
% blur kernel.
%
% NOTE: THIS PROGRAM REQUIRES THE MATLAB IMAGE PROCESSING TOOLBOX AND
% COMPUTER VISION SYSTEM TOOLBOX.

function main()

%#ok<*ASGLU,*AGROW,*NASGU,*NODEF>

run Initialization;                     % Initializing variables for this function space.
origImg   = activeImg;                  % Save original image for later.
activeImg = convGrayscale(activeImg);   % Convert working image to grayscale.
if scaleFactor && scaleFactor ~= 1      % Image might be too big, decrease the size a bit if needed.
    activeImg = imresize(activeImg, scaleFactor, 'bilinear');
    origImg = imresize(origImg, scaleFactor, 'bilinear');
end
activeImg   = ((double(activeImg)/256).^2.2)*256;                   % Gamma correction.
overSatVals = (activeImg(:,:,1) > 250);                             % Determine which pixels will be masked by storing 
extension   = conv2(overSatVals, ones(size(blurKernel)), 'same');       % sat values in activeImg that are greater than 250.
activeMask  = (extension > 0);
staticImg   = activeImg;                                            % Store saturation mask  
origMask    = activeMask;

origXGrad(:,:,1) = conv2(staticImg(:,:,1), [1 -1], 'valid');    % conv2() returns the 2d convolution of the two matrices.
origYGrad(:,:,1) = conv2(staticImg(:,:,1), [1 -1]', 'valid');   % 'valid' says to return only the parts of the convolution 
                                                                % that AREN'T computed with the zero-padded edges. 

% Store user-defined patch area using image/gradient space, and form scale
% pyramid.
activeMask = origMask(pCoord(2):pCoord(2)+pRange(2)-1, pCoord(1):pCoord(1)+pRange(1)-1);    % Pulling patch out from image.
origXGrad = origXGrad(pCoord(2):pCoord(2)+pRange(2)-1, pCoord(1):pCoord(1)+pRange(1)-1, :); % Pulling patch out from gradients.
origYGrad = origYGrad(pCoord(2):pCoord(2)+pRange(2)-1, pCoord(1):pCoord(1)+pRange(1)-1, :);    
resizeXGrad{kernelScales} = origXGrad;  % Creating cells of image and gradient
resizeYGrad{kernelScales} = origYGrad;  % patches to prepare scale pyramid.
resizeScale{kernelScales} = activeMask;

% Handles resizing the image patch and gradient patch.
for i = 2:kernelScales % Forming scale pyramid by resizing each cell'i patch to be a different size.
    resizeXGrad{kernelScales - i+1} = imresize(origXGrad, (1/sqrt(2))^(i-1), 'bilinear');       
    resizeYGrad{kernelScales - i+1} = imresize(origYGrad, (1/sqrt(2))^(i-1), 'bilinear');              
    resizeScale{kernelScales - i+1} = ceil(abs(imresize(activeMask, (1/sqrt(2))^(i-1), 'nearest'))); % Compute saturation mask for each.
end  
for i = 1:kernelScales                                      % Concatenate the gradient images together.
    activeGradSet{i} = [resizeXGrad{i}, resizeYGrad{i}];    % Each cell in activeGradSet contains a "gradient image" of the original image.
end                                                         % The difference being that each has been resized uniquely.
activeKSet{kernelScales} = blurKernel;                      % Array of size kernelScales that has an uninitialized kernel in each cell.

% Another resizing loop to scale a set (array) of blur kernels.  
% Handles creating, initializing, and resizing the set of blur kernels 
% placed in activeKSet.
for i = 2:kernelScales
    numDim = size(activeKSet{kernelScales}) * (1/sqrt(2))^(i-1);
    numDim = numDim + (1 - mod(numDim, 2));             % Check for odd. 
    if min(numDim) < 4   
        lowpFilter = fspecial('gaussian', numDim, 1);   % Creating mask and then applying to each kernel scale.
        activeKSet{kernelScales - i+1} = imresize(conv2(blurKernel, lowpFilter), numDim, 'nearest');
    else 
        activeKSet{kernelScales - i+1} = imresize(blurKernel, numDim, 'bilinear');           
    end  
    activeKSet{kernelScales - i+1} = activeKSet{kernelScales - i+1} / sum(activeKSet{kernelScales - i+1}(:));
end
[activeGradSet, resizeScale] = prepBlurs(activeKSet, activeGradSet, resizeScale, kernelScales); % Literally preps blur frames.

for i = 1:kernelScales  % Loop will use the image gradient and blur kernel sizes to make spatial filters.
    kSetSizes(i)  = size(activeKSet{i}, 1);               % Array of sizes of blur kernels.
    imgD1Sizes(i) = size(activeGradSet{i}, 1);            % Arrays of sizes of image gradients in both X and Y dimension.
    imgD2Sizes(i) = size(activeGradSet{i}, 2);
    spfBlur{i}    = zeros(4, kSetSizes(i)*kSetSizes(i));  % spfBlur and spfImage are both spatial filters (masks) for the gradient and image patch.
    spfImage{i}   = [zeros(size(resizeScale{i})), zeros(size(resizeScale{i}))];

    satRects{i} = zeros((2*imgD1Sizes(i)), (2*imgD2Sizes(i)));
    satRects{i}(kSetSizes(i):imgD1Sizes(i), kSetSizes(i):imgD2Sizes(i)/2) = 1;                % Rows from kSetSizes(i) to imgD1Sizes(i) from columns kSetSizes(i) to imgD2Sizes(2)/2 will be set to 1.
    satRects{i}(kSetSizes(i):imgD1Sizes(i), kSetSizes(i)+imgD2Sizes(i)/2:imgD2Sizes(i)) = 1;  % Same as above, but affected columns are shifted right so there will be two rectangles in satRects.
    padEmbsdBird{i} = padarray(activeGradSet{i}, [imgD1Sizes(i) imgD2Sizes(i)], 0, 'post');     % Output should appear as as an "embossed" double image of patch subject that highlights blur lines.
                                                                                                % This frame will be used for the gradient image in the ensemble library.
    % Now add in saturation mask
    satRects{i} = satRects{i} .* padarray(1-[resizeScale{i}, resizeScale{i}], [imgD1Sizes(i) imgD2Sizes(i)], 0, 'post');
end

% This loops runs the inferencing algorithm.
for i = 1:kernelScales 
    if (kernelScales - i+1) > 8
        priors(kernelScales - i+1) = priors(8);
    end     
    
    % ensembleTable breakdown:
    %
    % C1: Number of dimensions.                         C2: Size of dimension.
    % C3: Slots in prior array used.                    C4: Which prior is being used.
    % C5: Whether to lock prior during inference.       C6: Update parameter.
    
    ensembleTable = [1  1                            1  0  0  1;
                     1  kSetSizes(i)*kSetSizes(i)    4  1  1  1;
                     1  imgD1Sizes(i)*imgD2Sizes(i)  4  0  1  1];
                 
    if i == 1 % The return value of NoName will be vectors. Variational is only used on the first iteration, direct is used thereafter.
        [retFVal, retSVal] = iterVari(activeGradSet{i}, activeKSet{i}, activeGradSet{i}, ... 
                                      activeKSet{i}, fBlurMode, spfImage{i}, ... 
                                      priors(kernelScales-i+1));                            
    else 
        [retFVal, retSVal] = iterDirect(upKernel{i-1}, upGradient{i-1}, spfImage{i});                                     
    end 
    [useless, ensD{i}, ~] = train_ensemble_main6(ensembleTable, retFVal, retSVal, '', ['Scale = ' int2str(i)], [5e-4 0 1 0 0 50000 0], ...
                                            padEmbsdBird{i}, satRects{i}, 2*imgD1Sizes(i), 2*imgD2Sizes(i), kSetSizes(i), kSetSizes(i), ...
                                            imgD1Sizes(i), imgD2Sizes(i), priors(kernelScales - i+1), 1, spfBlur{i}, 1 - (spfImage{i}(:) > 0));
                                               
    % biKernel and biGradient are the estimated inference outputs at each scale.
    biKernel{i} = reshape(train_ensemble_get(2, ensembleTable, useless.mx), kSetSizes(i), kSetSizes(i)); 
    biGradient{i} = reshape(train_ensemble_get(3, ensembleTable, useless.mx), imgD1Sizes(i), imgD2Sizes(i), 1);
    
    if i ~= kernelScales % Upsample patch and kernel, but skip last iteration as upsampling isn't needed. 
        [upGradient{i}, upKernel{i}] = upSample(biGradient{i}, biKernel{i}, kSetSizes(i+1), ...
                                              kSetSizes(i+1), imgD1Sizes(i+1), imgD2Sizes(i+1));
    end
    save('biMidrun.mat', 'biGradient', 'biKernel', 'upGradient', 'upKernel', 'useless', 'ensD'); % Store temporary mid-run info to disk.
end

save('varInitialization.mat', 'useless', 'ensembleTable', ...
            'origImg', 'staticImg', 'activeGradSet', ...
            'origMask', 'activeKSet', 'blurKernel',  ...
            'biGradient', 'biKernel', 'upGradient',  ...
            'upKernel', 'pCoord', '-append');
    
[finImg, blurKernelO] = preDecon('varInitialization.mat', LR_Iterations);  % Richarson-Lucy deconvolution algorithm.
save('varInitialization.mat', 'finImg', 'blurKernelO', '-append');         % Save final image and kernel 
