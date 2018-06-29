function activeImg = convGrayscale(activeImg)
 
spFilter = (activeImg(:, :, 1) > 250) | ... % Criteria for saturated pixels.
           (activeImg(:, :, 2) > 250) | ...
           (activeImg(:, :, 3) > 250);      
clrChannels = reshape(activeImg(:), (size(activeImg, 1) * size(activeImg, 2)), 3); % Grab color channels to look for saturated pixels.
activeImg = zeros([size(activeImg,1), size(activeImg,2)]);
T = inv([1.0  0.956  0.621;                 % Invert matrix for reshape transformation.
         1.0 -0.272 -0.647; 
         1.0 -1.106  1.703]);

if isa(clrChannels, 'uint8') % JPEG  
    activeImg = uint8(reshape(double(clrChannels) * T(1, :)', size(activeImg)));
elseif isa(clrChannels, 'uint16') % Just in case, although not sure which image type corresponds to this.
    activeImg = uint16(reshape(double(clrChannels) * T(1, :)', size(activeImg)));
elseif isa(clrChannels, 'double') % PNG    
    activeImg = reshape(clrChannels * T(1,:)', size(activeImg));
    activeImg = min(max(activeImg, 0), 1);
end
activeImg(spFilter) = 255; % Mask saturation.