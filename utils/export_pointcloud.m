function export_pointcloud(data_vectors,  out_directory , name)

location = data_vectors(:,1:3);
color = data_vectors(:,4);

ptcloud = pointCloud(location, 'Intensity', color);
outpath = strcat( out_directory, name, '.ply');
pcwrite(ptcloud,outpath);








% outpath = strcat( 'C:\Users\Ben\Desktop\master_ek80proc\pointclouds\', name, '.ply');

% if(strcmp(coord_type, 'local'));
%     comp_x = min(location(:,1));
%     comp_y = min(location(:,2));
%     
%     if(comp_x <0)
%         location(:,1) = location(:,1)+ comp_x;
%     end
%     if(comp_y <0)
%         location(:,2) = location(:,2)+ comp_y;
%     end
%     
%     location(:,1) = location(:,1)* scale_range;
%     location(:,2) = location(:,2)* scale_range;
%     location(:,3) = location(:,3)* scale_depth;
% else 
%     location(:,2) = location(:,2)* scale_range;
%     location(:,3) = location(:,3)* scale_depth;
% end
