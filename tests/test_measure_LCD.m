
function test_suite = test_measure_LCD
    try
        test_functions = {
            @test_directory_input,
            @test_array_input,
            @test_observer_input
        };

        for i = 1:length(test_functions)
            fprintf('Running %s...\n', func2str(test_functions{i}));
            test_functions{i}();
            fprintf('%s passed.\n', func2str(test_functions{i}));
        end
        fprintf('All tests passed.\n');
    catch ME
        fprintf('Test failed: %s\n', ME.message);
        fprintf('Stack trace:\n');
        for k = 1:length(ME.stack)
            fprintf('  File: %s, Line: %d, Name: %s\n', ...
                    ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
        end
        exit(1);
    end
end

function setup_environment
    if is_octave
        pkg load image
    end
    addpath(genpath('src'));
end

function test_directory_input
    setup_environment();

    % Use existing small dataset
    base_directory = 'data/small_dataset';
    dose = 100;
    recon_dir = fullfile(base_directory, 'fbp', ['dose_' num2str(dose, '%03d')]);

    ground_truth_fname = fullfile(base_directory, 'fbp', 'ground_truth.mhd');
    offset = 1000;
    ground_truth = mhd_read_image(ground_truth_fname) - offset;

    observers = {LG_CHO_2D()};

    % Test call
    res = measure_LCD(recon_dir, observers, ground_truth, offset, 2, 0.5); % Reduced n_reader for speed

    % Validations
    if is_octave
       assert(isfield(res, 'dose_level'));
       assert(all(res.dose_level == 100));
    else
       assert(istable(res));
       assert(all(ismember({'auc', 'snr', 'diameter', 'dose_level'}, res.Properties.VariableNames)));
       assert(all(res.dose_level == 100));
    end
end

function test_array_input
    setup_environment();

    % Manually load images to pass as arrays
    base_directory = 'data/small_dataset';
    dose = 100;
    recon_dir = fullfile(base_directory, 'fbp', ['dose_' num2str(dose, '%03d')]);

    sp_dir = fullfile(recon_dir, 'signal_present');
    sa_dir = fullfile(recon_dir, 'signal_absent');

    sp_img = mhd_read_image(fullfile(sp_dir, 'signal_present.mhd'));
    sa_img = mhd_read_image(fullfile(sa_dir, 'signal_absent.mhd'));

    ground_truth_fname = fullfile(base_directory, 'fbp', 'ground_truth.mhd');
    offset = 1000;
    ground_truth = mhd_read_image(ground_truth_fname) - offset;
    sp_img = sp_img - offset;
    sa_img = sa_img - offset;

    observers = {LG_CHO_2D()};

    % Test call
    res = measure_LCD(sp_img, sa_img, ground_truth, observers, 2, 0.5);

    % Validations
    if is_octave
       assert(all(isnan(res.dose_level)));
    else
       assert(all(isnan(res.dose_level))); % Dose level should be NaN for array input
    end
end

function test_observer_input
    setup_environment();

    base_directory = 'data/small_dataset';
    dose = 100;
    recon_dir = fullfile(base_directory, 'fbp', ['dose_' num2str(dose, '%03d')]);
    ground_truth_fname = fullfile(base_directory, 'fbp', 'ground_truth.mhd');
    offset = 1000;
    ground_truth = mhd_read_image(ground_truth_fname) - offset;

    % Test with mixed string and object input
    observers = {'LG_CHO_2D', LG_CHO_2D()};

    res = measure_LCD(recon_dir, observers, ground_truth, offset, 2, 0.5);

    % Should produce results for both observers
    if is_octave
        assert(length(res.auc) > 0);
    else
        % Check if we have enough rows or entries corresponding to 2 observers
        % Each observer has N readers * M inserts
        % Just check that it runs without error and produces output
        assert(height(res) > 0);
    end
end

% Helper function for Octave compatibility
function b = is_octave
  b = exist('OCTAVE_VERSION', 'builtin');
end
