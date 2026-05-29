function dataout = combine_unequal_data(cellgroup)

nvar = length(cellgroup);
max_dim = max(cellfun(@length, cellgroup));
dataout = NaN(max_dim,nvar);
for i = 1:numel(cellgroup)
    dataout(1:length(cellgroup{i}), i) = cellgroup{i};
end

end