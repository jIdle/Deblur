function [retFVal, retSVal] = iterDirect(activeBlur, upGradient, spfImage)

biKernel = activeBlur;
spfImage = spfImage(:);
biGradient = upGradient;
biKernel = biKernel / sum(biKernel(:)); % Normalize kernel to 1.

vecMask = ones(1, length(biKernel(:)) + length(biGradient(:)) + 1) * 1e4; % Apply filter to kernel.
nonZero = find(spfImage(:));
vecMask(nonZero + 1 + length(biKernel(:))) = spfImage(nonZero)';

retFVal = [zeros(1, 1) biKernel(:)' biGradient(:)'] .* vecMask; % Create masked gradient and kernel vectors for output.  
retSVal = vecMask;