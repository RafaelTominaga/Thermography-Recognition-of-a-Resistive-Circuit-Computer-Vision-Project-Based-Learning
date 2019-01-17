function [ result ] = thermanalyze_b300( input_image, input_temp_max, input_temp_min )
%% Input parameter settings
% Starting the stopwatch count
tic
% Checking if temperature limits are reversed
if input_temp_max < input_temp_min
    input_temp_change = input_temp_max;
    input_temp_max = input_temp_min;
    input_temp_min = input_temp_change;
end
% Internal system parameters
pixel_step = 1;
tolerance = 5;
%% Image reading
image_color_data = imread(input_image);
reference_color_data = image_color_data(62:177,298:305,:);
%% Temperature reference
reference_max_pixel = length(reference_color_data);
reference_temperature = NaN(reference_max_pixel,1);
for reference_pixel = 1:reference_max_pixel
    reference_temperature(reference_pixel,1) = input_temp_max - (input_temp_max - input_temp_min)*((reference_pixel-1)/(reference_max_pixel-1));
end
%% Temperature image
% Collecting the dimensions of the input image
[thermal_xmax,thermal_ymax] = size(image_color_data);
thermal_ymax = thermal_ymax/3;
% Initializing predefined-dimensions variables
thermal_temperature = NaN(thermal_xmax,thermal_ymax);
cond_color = NaN(1,3);
% Checks if the step is an integer multiple of the dimensions of the input
% image.
while mod(thermal_xmax,pixel_step) + mod(thermal_ymax,pixel_step) ~= 0
    pixel_step = pixel_step - 1;
end
% Collecting the dimensions of the color scale
[~,reference_max_pixel_c]=size(reference_color_data);
reference_max_pixel_c = reference_max_pixel_c/3;
% Converts color to temperature
for reference_pixel_c = 1:reference_max_pixel_c
    for thermal_x = pixel_step:pixel_step:thermal_xmax
        for thermal_y = pixel_step:pixel_step:thermal_ymax
            if isnan(thermal_temperature(thermal_x,thermal_y)) == 1
                for reference_pixel = 1:reference_max_pixel
                    for count_color = 1:3
                        if image_color_data(thermal_x,thermal_y,count_color) > reference_color_data(reference_pixel,reference_pixel_c,count_color)
                            if image_color_data(thermal_x,thermal_y,count_color) - reference_color_data(reference_pixel,reference_pixel_c,count_color) <= tolerance
                                cond_color(count_color) = 1;
                            else
                                cond_color(count_color) = 0;
                            end
                        else
                            if reference_color_data(reference_pixel,reference_pixel_c,count_color) - image_color_data(thermal_x,thermal_y,count_color) <= tolerance
                                cond_color(count_color) = 1;
                            else
                                cond_color(count_color) = 0;
                            end
                        end
                    end
                    if cond_color(1) == 1 && cond_color(2) == 1 && cond_color(3) == 1
                        thermal_temperature(thermal_x,thermal_y) = reference_temperature(reference_pixel,1);
                    end
                end
            end
        end
    end
end
%% Comparing the input with the library
result = NaN(1,2);
file_score = 0;
file_list = 1;
for file_count = 0:1:9999
    if exist(strcat('FLIR_B300_',num2str(file_count,'%0.4d'),'.csv'),'file') == 2
        file_data = csvread(strcat('FLIR_B300_',num2str(file_count,'%0.4d'),'.csv'));
        for thermal_x = pixel_step:pixel_step:thermal_xmax
            for thermal_y = pixel_step:pixel_step:thermal_ymax
                if abs(file_data(thermal_x,thermal_y) - thermal_temperature(thermal_x,thermal_y)) < tolerance*(input_temp_max - input_temp_min)/(reference_max_pixel-1)
                    file_score = 1/(thermal_xmax*thermal_ymax) + file_score;
                end
            end
        end
        result(file_list,1) = file_count;
        result(file_list,2) = file_score;
        file_list = file_list + 1;
        file_score = 0;
    end
end
%% results
% Generating results in graphic form
bar(1:length(result),transpose(result(:,2)))
xlim([0 length(result)+1])
grid on
grid minor
xlabel('Library File')
ylabel('Compatibility')
% Adding the list with possible comments
[~,ref_txt] = xlsread('diagnosis_list.xlsx');
% Checking the most likely diagnosis
[probability_value,element_probability_value] = max(result(:,2));
% Determining the code of the diagnosis
image_code = result(element_probability_value,1);
% Interpreting the code of the diagnosis
case_image = image_code/10;
number_image = mod(image_code,10);
case_image = case_image - number_image/10;
% Sending answer
disp(ref_txt(case_image+1));
disp(strcat('Compatibility: ',num2str(probability_value*100,'%.2f'),'%'));
% Stopping the stopwatch count
toc
end