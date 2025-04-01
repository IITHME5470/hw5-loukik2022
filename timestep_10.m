clc;
clear;

nx = 800; 
ny = 800;  

% Initialize matrices
parallel_solution = NaN(nx, ny); 
serial_solution = NaN(nx, ny);  

parallel_files = dir('parallel_000010_*.dat');

for file = parallel_files'
    filename = file.name;
    data = load(filename);
    
    i = data(:,1) + 1; % Convert to 1-based index
    j = data(:,2) + 1;
    T = data(:,3);
    
    for k = 1:length(i)
        parallel_solution(i(k), j(k)) = T(k);
    end
end

serial_data = load('serial_000010.dat');
i_serial = serial_data(:,1) + 1;  
j_serial = serial_data(:,2) + 1;
T_serial = serial_data(:,3);

for k = 1:length(i_serial)
    serial_solution(i_serial(k), j_serial(k)) = T_serial(k);
end

differences = abs(serial_solution - parallel_solution);

% Compute min, max, and average difference
max_diff = max(differences(:));
min_diff = min(differences(:));
avg_diff = mean(differences(:));

fprintf('Comparison of Serial and Parallel Runs After 10 Time Steps:\n');
fprintf('-------------------------------------------------------------\n');
fprintf('Maximum Difference: %.20e\n', max_diff);
fprintf('Minimum Difference: %.20e\n', min_diff);
fprintf('Average Difference: %.20e\n', avg_diff);

tolerance = eps;
if max_diff < tolerance
    fprintf('\nAll differences are within machine precision.\n');
else
    fprintf('\nSome differences exceed machine precision!\n');
end