function [filter, pFilter] = Clutter(iRows, iColumns, kRows, kColumns, activeGrad)

filter = zeros(iRows*2, iColumns*2, 1);
filter(kRows:iRows, kColumns:iColumns/2, :) = 1;
filter(kRows:iRows, (kColumns + iColumns/2):iColumns, :) = 1;
pFilter = padarray(activeGrad, [iRows iColumns], 0, 'post');