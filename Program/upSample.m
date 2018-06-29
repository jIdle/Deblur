function [biGradientO, biKernelO] = upSample(biGradient, biKernel, kRows, kColumns, iRows, iColumns)

fprintf('Centering kernel\n');
biKernel = biKernel / sum(biKernel(:));                             % Normalize kernel to 1.
blurCenterY = sum((1:size(biKernel, 1)) .* sum(biKernel, 2)');      % Calculates center of blur, not kernel just to note.
blurCenterX = sum((1:size(biKernel, 2)) .* sum(biKernel, 1));    
blurOffsetX = round(floor(size(biKernel, 2)/2) + 1-blurCenterX);    % Using the blur center, this calculates the mean offset of
blurOffsetY = round(floor(size(biKernel, 1)/2) + 1-blurCenterY);        % the blur from the kernel center.

translate = zeros(abs(blurOffsetY*2) + 1, abs(blurOffsetX*2) + 1);  % Translation factor for kernel to adjust to blur offset.
translate(abs(blurOffsetY) + blurOffsetY + 1, abs(blurOffsetX) + blurOffsetX + 1) = 1;
biKernel = conv2(biKernel, translate, 'same');                      % The actual adjustment.
biGradChannels = size(biGradient, 3);                               % Grab image gradient channels.
for i = 1:biGradChannels
  biGradient(:, :, i) = conv2(biGradient(:, :, i), rot90(translate,2), 'same');
end
  
biGradientO = imresize(biGradient,[iRows iColumns],'bilinear');
biKernelO = imresize(biKernel,[kRows kColumns],'bilinear');
kSum = sum(biKernelO(:)); % Normalize kernel.
biKernelO = biKernelO / kSum;