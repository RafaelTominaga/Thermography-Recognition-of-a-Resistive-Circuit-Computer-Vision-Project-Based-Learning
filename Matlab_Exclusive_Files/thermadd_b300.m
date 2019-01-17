%% 1. Cleaning workspace and command window
% This is important to ensure that there is no interference to the result
% caused by variables already in the workspace.
clear
clc
tic
%% 2. Input arguments
% Here are the program input parameters. The operator should only change 
% the parameters in this field to obtain the desired result.
% 
% 1) thermal_image: name of the image file to be processed;
% 2) reference_temperature_max: maximum temperature shown by the thermal 
%    imager;
% 3) reference_temperature_min: minimum temperature shown by the thermal 
%    imager;
% 4) pixel_step: influences the amount of pixels of the image that will be 
%    processed. The higher, the faster the image is processed, but the 
%    results are less precise;
% 5) tolerance: parameter that indicates how much error will be accepted 
%    for image processing. The higher these parameter, the higher are the 
%    chances of each pixel having some corresponding temperature value, but
%    the greater the error added to the reading value;
% 6) name_file_csv: Name of the file to be saved.
thermal_image = 'IR_0375.jpg';
reference_temperature_max = 131;
reference_temperature_min = 25.5;
pixel_step = 1;
tolerance = 5;
name_file_csv = 'FLIR_B300_CODE.csv';
%% 3. Image reading
% Performing a reading of the RGB components of each pixel in the image.
image_color_data = imread(thermal_image);
reference_color_data = image_color_data(62:177,298:305,:);
%% 4. Imagem showing
% Displays the image that has been read by the program. This helps show
% which is the program input image.
figure(1);
imagesc(image_color_data);
%% 5. Temperature reference
% Generates a list of the possible temperature values that can be obtained
% in the image. Note that this list is made with the help of the color bar.
reference_max_pixel = length(reference_color_data);
reference_temperature = NaN(reference_max_pixel,1);
for t = 1:reference_max_pixel
    reference_temperature(t,1) = reference_temperature_max - (reference_temperature_max - reference_temperature_min)*((t-1)/(reference_max_pixel-1));
end
%% 6. Temperature image
% This is the most time consuming part of running the program, so the tic
% and toc function is used. It scans each pixel in the input image and 
% tries to find a temperature that best represents that pixel with the RGB 
% components. Note that there is a tolerance for this conversion. Pixels 
% that do not have a temperature that well-represents, are filled with the 
% value nan (not a number).
[thermal_xmax,thermal_ymax] = size(image_color_data);
thermal_ymax = thermal_ymax/3;
thermal_temperature = NaN(thermal_xmax,thermal_ymax);
cond_color = NaN(1,3);
while mod(thermal_xmax,pixel_step) + mod(thermal_ymax,pixel_step) ~= 0
    pixel_step = pixel_step - 1;
end
[~,reference_max_pixel_c]=size(reference_color_data);
reference_max_pixel_c = reference_max_pixel_c/3;
for reference_pixel_c = 1:reference_max_pixel_c
    for thermal_x = pixel_step:pixel_step:thermal_xmax
        for thermal_y = pixel_step:pixel_step:thermal_ymax
            if isnan(thermal_temperature(thermal_x,thermal_y)) == 1
                for t = 1:reference_max_pixel
                    for count_color = 1:3
                        if image_color_data(thermal_x,thermal_y,count_color) > reference_color_data(t,reference_pixel_c,count_color)
                            if image_color_data(thermal_x,thermal_y,count_color) - reference_color_data(t,reference_pixel_c,count_color) <= tolerance
                                cond_color(count_color) = 1;
                            else
                                cond_color(count_color) = 0;
                            end
                        else
                            if reference_color_data(t,reference_pixel_c,count_color) - image_color_data(thermal_x,thermal_y,count_color) <= tolerance
                                cond_color(count_color) = 1;
                            else
                                cond_color(count_color) = 0;
                            end
                        end
                    end
                    if cond_color(1) == 1 && cond_color(2) == 1 && cond_color(3) == 1
                        thermal_temperature(thermal_x,thermal_y) = reference_temperature(t,1);
                    end
                end
            end
        end
    end
end
%% 7. Save as a csv file
% It is important, after having scanned, that the obtained data be saved in
% a csv file so that it can be used later.
csvwrite(name_file_csv,thermal_temperature);
%% 8. Showing obtained results
% Getting a graphical view of the result is always important to get a sense
% of how the results behave.
figure(2)
thermal_view = NaN(thermal_xmax/pixel_step,thermal_ymax/pixel_step);
for view_x = pixel_step:pixel_step:thermal_xmax
    for view_y = pixel_step:pixel_step:thermal_ymax
        plot_x = view_x/pixel_step;
        plot_y = view_y/pixel_step;
        thermal_view(plot_x,plot_y) = thermal_temperature(view_x,view_y);
    end
end
surf(pixel_step:pixel_step:thermal_xmax,pixel_step:pixel_step:thermal_ymax,transpose(thermal_view));
colormap jet
%% 9. Cleaning irrelevant variables
% Leaves only the most relevant variables of the script saved in the
% workspace.
clear thermal_image
clear reference_temperature_max reference_temperature_min
clear reference_max_pixel t
clear thermal_xmax thermal_ymax thermal_x thermal_y
clear tolerance pixel_step count_color cond_color
clear thermal_view view_x view_y plot_x plot_y
clear reference_max_pixel_c reference_pixel_c
clear name_file_csv
toc