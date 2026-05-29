function [valin,algin,athin,arb_param] = flyer_sync_fix_casts_alldata(valin,algin,athin,r_subset,t_subset,varargin)

if isempty(r_subset)
    r_subset = [];
elseif isempty(t_subset)
    t_subset = [];
end

if nargin>6
    if isstruct(varargin{1})
        arb_param = varargin{1};
    end
end

chname = fieldnames(valin);

for i=1:numel(chname)
    [valin,~,~] = flyer_cast_idx(valin, i); % Same casts as the 70kHz
    fprintf('[sync_flyer_cast_data] Fixed casts for channel %s\n',chname{i})
    cast_fixed = [valin.(chname{i}).vars.cast_new];
    cast_fixed_cell = num2cell(cast_fixed);
    [algin.(chname{i}).vars.cast_new] = deal(cast_fixed_cell{:});
    [athin.(chname{i}).vars.cast_new] = deal(cast_fixed_cell{:});
    if exist('arb_param','var')
        [arb_param.(chname{i}).vars.cast_new] = deal(cast_fixed_cell{:});
    end
end

valin = chop_EK60_EK80(valin,r_subset,t_subset);
algin = chop_EK60_EK80(algin,r_subset,t_subset);
athin = chop_EK60_EK80(athin,r_subset,t_subset);
if exist('arb_param','var')
    arb_param = chop_EK60_EK80(arb_param,r_subset,t_subset);
end

end