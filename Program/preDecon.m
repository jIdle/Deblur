function [finImg, blurKernel] = preDecon(nmFile, iterNum)
%#ok<*IDISVAR,*USENS,*NODEF,*LOAD,*AGROW>

load(nmFile);                                       % Load external data.
LR_Iterations = iterNum;                            % Set number of deconvolution iterations.
blurKernel = biKernel{end}/sum(biKernel{end}(:));   % Grab kernel from ensemble output.
threshold = max(blurKernel(:))/7;                   % Denominator controls the threshold. | Higher -> Less grain | Lower -> More grain
index = blurKernel(:) < threshold;
blurKernel(index) = 0;
blurKernel = blurKernel / sum(blurKernel(:));       % Normalize kernel to 1.

if scaleFactor ~= 1 % If image was resized to start, it will be resized here also.
  activeImg = imresize(activeImg, scaleFactor, 'bilinear'); 
end

gcInput = ((double(activeImg)/256).^2.2)*256;             % Remove gamma correction from deconvolution input image.
finImg  = deconvlucy(gcInput, blurKernel, LR_Iterations);   % Run deconvolution on image and kernel with gamma correction.    
finImg  = ((double(finImg)/256).^(1/2.2))*256;              % Add gamma back in.

finImg        = rescale(finImg);                            % Scale image from range 0 - 1 because it's a double.
gsDouble      = rgb2gray(finImg);                           % Convert both images to grayscale.
gsUint8       = rgb2gray(activeImg);
[binCount, ~] = histcounts(double(gsUint8(:)), 0:255);      % Grab bin counts to calculate histeq.
[~,transform] = histeq(gsDouble, binCount);                 % Grab histeq calculated transform to raise image contrast.
for i = 1:3                                                 % Scaling finImg RGB channels with the same transformation applied to grayscale gsDouble through histogram equalization.
    rgbVector        = finImg(:, :, i);
    tLookupTable     = interp1((0:255)/256, transform, rgbVector(:));
    finImg8(:, :, i) = uint8(256 * reshape(tLookupTable, size(finImg(:, :,i)))); % Simultaneously scaling channels and converting to uint8.
end
finImg = finImg8; % finImg8 can't be finImg while in the loop because finImg must remained unchanged.

rect = round(AXIS * (1/sqrt(2))^0);             % Show the user selected patch on the output blurry image.
activeImg(rect(3), rect(1):rect(2), :) = 75;
activeImg(rect(4), rect(1):rect(2), :) = 75;
activeImg(rect(3):rect(4), rect(1), :) = 75;
activeImg(rect(3):rect(4), rect(2), :) = 75;

edge_offset = floor(size(blurKernel, 1)/2);     % Cutting off the outer edges of the output because it looks messed up. 
finImg      = finImg(edge_offset+1:end-edge_offset-1, edge_offset+1:end-edge_offset-1, :);
activeImg   = activeImg(edge_offset+1:end-edge_offset-1, edge_offset+1:end-edge_offset-1, :);

WtF(finImg, activeImg, blurKernel);