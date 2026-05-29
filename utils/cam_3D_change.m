%% 3D Plot camera change
function cam_3D_change(ax1,ax2,angle_h,angle_v)
    ax1.View = [angle_h angle_v];
    ax2.View = [angle_h angle_v];
end