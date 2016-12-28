function neigh=neighbor(image_size,obj_coord,IndexorSubscript)
% neigh=neighbour(image_size,obj_coord,IndexorSubscript)
% Neighbour() is used to find the neighbours of simulated data with boundary 
% data_dim is the vector to specify the dimensions of data
% obj_coord is the coordinate of the object that I want to find neighbours
% neigh is the position of neighbours after data is reshaped
% the last element niegh(9) in neigh is the position of central voxel in the reshaped
% vector
if nargin == 2
    IndexorSubscript = 'index';
end
if numel(image_size)>3 && strcmpi(IndexorSubscript,'index')==1
    error('the dimension for index should be only 2 or 3');
end

neigh = zeros(9,numel(image_size));
neigh(1,1:2)=[obj_coord(1)  ,obj_coord(2)];
neigh(2,1:2)=[obj_coord(1)+1,obj_coord(2)-1];
neigh(3,1:2)=[obj_coord(1)+1,obj_coord(2)]  ;
neigh(4,1:2)=[obj_coord(1)+1,obj_coord(2)+1];
neigh(5,1:2)=[obj_coord(1)  ,obj_coord(2)+1];
neigh(6,1:2)=[obj_coord(1)-1,obj_coord(2)+1];
neigh(7,1:2)=[obj_coord(1)-1,obj_coord(2)];
neigh(8,1:2)=[obj_coord(1)-1,obj_coord(2)-1];
neigh(9,1:2)=[obj_coord(1)  ,obj_coord(2)-1];  

if numel(image_size)==3
    neigh(:,3:end) = obj_coord(3:end);
end

if strcmpi(IndexorSubscript,'index')==1
    if numel(image_size)==2
        neigh = sub2ind(image_size,neigh(:,1),neigh(:,2));
    elseif numel(image_size)==3
        neigh = sub2ind(image_size,neigh(:,1),neigh(:,2),neigh(:,3));
    end
end


    
end
