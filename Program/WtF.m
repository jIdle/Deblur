function WtF(finImg, activeImg, blurKernel)

figure;                             % Final image output prep.
imagesc(finImg); 
title('Final Image'); 
axis equal;

figure;                             % Original image prep.
imagesc(activeImg); 
title('Original Image'); 
axis equal;

blurFig = figure;                   % Kernel output image prep.
imagesc(blurKernel); 
colormap(gray);
axis square; 
title('Estimated Blur Kernel');

ExportFig(blurFig, 'Blur_Kernel');  % Write final products to file.
imwrite(uint8(activeImg), 'Original.jpg', 'jpg','Quality', 100);
imwrite(uint8(finImg), 'Output.jpg', 'jpg', 'Quality', 100);