function dataout = filt_remove_idx(dataref,chnum_ref,datain)

chan = fieldnames(dataref);
rem_idx = find_filtered_idx(dataref,chnum_ref);

dataout = datain;
valEK80 = [datain.(chan{chnum_ref}).val];
valEK80(rem_idx) = NaN;

if ~all(size(rem_idx) == size(valEK80))
    error('Size of reference and input are not compatible!');
else
    dataout.(chan{chnum_ref}).val = valEK80;
end

end