function [subdata,ind]=neighIrregular(Data,sub_coord)
% [subdata,ind]=neighIrregular(Data,sub_coord)
% This function is used to find the 9 neighbours of any coordinates
% return the data relative to the sub_coord
% subdata: N x Nvoxels
% ind : Nvoxels x 9
siz =size(Data);% [Nsample, dimension]
if numel(siz)-1>3
    err('maximum dimension is 3 in function neighIrregular');
end

ind = zeros(size(sub_coord,1),9); % [central voxels, 8 neighbours]

for i = 1:size(sub_coord,1)
    temp = zeros(9,numel(siz)-1);
    temp(:,1) = [0;-1;-1;-1;0;0;1;1;1];
    temp(:,2) = [0;1;0;-1;1;-1;1;0;-1];
    neigh = repmat(sub_coord(i,:),9,1)+temp;
    if numel(siz)==4
        ind(i,:) = sub2ind(siz(2:end),neigh(:,1),neigh(:,2),neigh(:,3));
    elseif numel(siz)==3
        ind(i,:) = sub2ind(siz(2:end),neigh(:,1),neigh(:,2));
    else
        err('The dimension is not specified in function neighIrregular');
    end
end

% find all central coordinates and their neighbours
unq = unique(ind(:),'stable'); % the first (1:size(CA1coord,1)) are the central voxels
subdata = zeros(size(Data,1),size(unq,1));

for i = 1:size(unq,1)
    ind(ind==unq(i)) = i;
    if numel(siz)==4
        [x,y,z] = ind2sub(siz(2:end),unq(i));
        subdata(:,i) = squeeze(Data(:,x,y,z));
    else
        [x,y] = ind2sub(siz(2:end),unq(i));
        subdata(:,i) = squeeze(Data(:,x,y));
    end
end

end