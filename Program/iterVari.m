function [retFVal,retSVal] = iterVari(activeGrad, activeBlur, upGradient, firstBlur, blurMode, spfImage, priors)

[kRows, kColumns] = size(firstBlur);
splitRow = floor(kRows/2) + 1;
splitCol = floor(kColumns/2) + 1;
biKernel = zeros(kRows, kColumns);
biKernel(splitRow, splitCol) = 1;

if strcmp(blurMode, 'hbar') % Depending on user selection.
    biKernel(splitRow ,splitCol - 1) = 1;
    biKernel(splitRow, splitCol + 1) = 1;
elseif strcmp(blurMode, 'vbar')
    biKernel(splitRow - 1, splitCol) = 1;
    biKernel(splitRow + 1, splitCol) = 1;
end

spfImage = spfImage(:);
[iRows, iColumns] = size(upGradient);
[kRows, kColumns] = size(activeBlur);
normTemp = biKernel / sum(biKernel(:));
dimensions = [1 1              1  0  0  1;
              1 kRows*kColumns 4  1  0  0;
              1 iRows*iColumns 4  0  1  1];

[filter, pFilter] = Clutter(iRows, iColumns, kRows, kColumns, activeGrad); % Below we create and apply filter to kernel.
vecMask = ones(1, length(normTemp(:)) + length(upGradient(:)) + 1) * 1e4;
nonZero = find(spfImage(:));
vecMask(nonZero + 1 + length(normTemp(:))) = spfImage(nonZero)';
bMask = zeros(dimensions(2, 3), length(normTemp(:)));

inFVal = [0 normTemp(:)' upGradient(:)'] .* vecMask; % Create masked gradient and kernel vectors for ensemble input.  
inSVal = vecMask;
[useless, ~, ~] = train_ensemble_main6(dimensions, inFVal, inSVal, '' , '', ...
                            [1e-4 0 1 0 0 5000 0], pFilter, filter, iRows*2, ...
                            iColumns*2, kRows, kColumns, iRows, iColumns, ...
                            priors, 1, bMask, (1 - (spfImage > 0)));    
biGradient = reshape(train_ensemble_get(3, dimensions, useless.mx), iRows, iColumns, 1);

biKernel = biKernel / sum(biKernel(:));                                     % Normalize kernel output again.
vecMask = ones(1, length(biKernel(:)) + length(biGradient(:)) + 1) * 1e4;   % Create and apply filter to gradient and kernel again.
nonZero = find(spfImage(:));
vecMask(nonZero + 1 + length(biKernel(:))) = spfImage(nonZero)';

retFVal = [zeros(1, 1) biKernel(:)' biGradient(:)'] .* vecMask;             % Create masked gradient and kernel vectors for output.
retSVal = vecMask;
