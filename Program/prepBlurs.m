function [activeGradSet, resizeScale] = prepBlurs(activeKSet, activeGradSet, resizeScale, kernelScales)
%#ok<*AGROW>
for i = 1:kernelScales
    tempSize = size(activeKSet{i}, 1);
    if mod(tempSize, 2) == 0
        tempSize = tempSize + 1;
    end
    oddDim = zeros(tempSize);
    tempDim = floor(tempSize/2) + 1;
    oddDim(tempDim, tempDim) = 1; 
    activeGradSet{i}(:,:,1) = real(ifft2(fft2(activeGradSet{i}(:,:,1)).*fft2(oddDim, size(activeGradSet{i}, 1), size(activeGradSet{i}, 2))));  
    resizeScale{i} = conv2(double(resizeScale{i}), oddDim, 'same'); % Pushing the array of saturation masks through convolutions also.
end %activeGradSet is the array of uniquely resized image gradients. This loop uses them to prepare "blurs".