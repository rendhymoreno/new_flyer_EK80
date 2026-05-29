function max_range = calc_surface_rejection(tri_min_depth, tri_max_depth, ping_depth)

%only deals with 100m range, add input var
tri_height = tri_max_depth - tri_min_depth;
ping_height = tri_max_depth - ping_depth;  

max_range =  100 - 100*ping_height/tri_height;
