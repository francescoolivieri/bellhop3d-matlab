# API Reference - UnderwaterModeling3D

## 🔊 Acoustic Modeling Functions

### Core Forward Model

**`forward_model(theta, pos, s)`**
- **Purpose**: 3D acoustic transmission loss prediction using BELLHOP3D
- **Inputs**:
  - `theta [2×1]`: Bottom parameters `[sound_speed_m/s; density_factor]`
  - `pos [N×3]`: Measurement positions `[x_km, y_km, z_m]`
  - `s`: Settings structure from `get_sim_settings()`
- **Output**: `tl [N×1]`: Transmission loss in dB
- **Example**:
  ```matlab
  theta = [1600; 1.5];  % Sand bottom
  pos = [0.5, 0.0, 20]; % 500m range, 20m depth
  tl = forward_model(theta, pos, s);
  ```

**`prediction_error_loss(pos, mu_th, Sigma_thth, s)`**
- **Purpose**: Loss function for NBV planning (prediction variance)
- **Use**: Quantifies expected uncertainty reduction at candidate positions

### BELLHOP Integration

**`writeENV3D(filename, s, theta)`**
- **Purpose**: Generate BELLHOP3D environment files
- **Inputs**: Filename, settings, bottom parameters

**`writeBTY3D(filename, scene, speed, density)`**
- **Purpose**: Generate bathymetry files for complex seafloor

**`writeSSP3D(filename, ...)`**
- **Purpose**: Generate sound speed profile files

## 📊 Parameter Estimation Functions

### Bayesian Estimation (UKF)

**`step_ukf_filter(measurement, forward_model_fn, mu_prior, Sigma_prior, R)`**
- **Purpose**: One step of Unscented Kalman Filter for parameter estimation
- **Inputs**:
  - `measurement`: Observed transmission loss [dB]
  - `forward_model_fn`: Function handle `@(theta) forward_model(theta, pos, s)`
  - `mu_prior [2×1]`: Prior parameter mean
  - `Sigma_prior [2×2]`: Prior parameter covariance
  - `R`: Measurement noise covariance
- **Outputs**: `[mu_posterior, Sigma_posterior]`

**`ukf(f, h, mu, Sigma, Q, R, y)`**
- **Purpose**: Full UKF prediction-update cycle
- **Use**: General nonlinear state estimation

**`unscented_transform(f, mu, Sigma)`**
- **Purpose**: Propagate uncertainty through nonlinear functions
- **Use**: Core UKF computation

### Filter Initialization

**`init_filter(data, s)`**
- **Purpose**: Initialize parameter estimation
- **Sets up**: Prior estimates, measurement storage, position arrays

## 🧠 Gaussian Process Modeling

### Sound Speed Field Generation

**`gen_sound_speed_gp(gridX, gridY, gridZ)`**
- **Purpose**: Generate 3D sound speed field using GP with CTD data
- **Inputs**: 3D coordinate grids
- **Output**: Sound speed field with spatial correlation
- **Parameters**:
  - `ell_h = 300`: Horizontal correlation length [m]
  - `ell_v = 20`: Vertical correlation length [m]
  - `sigma_f = 1`: Signal variance

**`generateSSP3D(s, ...)`**
- **Purpose**: Create structured sound speed profiles for BELLHOP

## 🚁 Intelligent Sensor Placement

### Next-Best-View Planning

**`pos_next_measurement(data, s)`**
- **Purpose**: Plan next optimal measurement location
- **Method**: Tree-based planning with memoization
- **Use**: Basic NBV with 9-action motion model

**`pos_next_measurement_sota(data, s)`**
- **Purpose**: Advanced NBV planning with multiple algorithms
- **Methods Available**:
  - `'rrt_star_nbv'`: Optimal for autonomous vehicles
  - `'information_gain'`: Direct information optimization
  - `'uncertainty_guided'`: GP uncertainty-driven
  - `'multi_objective'`: Balanced multiple objectives
- **Example**:
  ```matlab
  s.nbv_method = 'rrt_star_nbv';
  data = pos_next_measurement_sota(data, s);
  ```

### Motion Models

**`update_pos(x, y, z, s, action)`**
- **Purpose**: 9-action discrete motion model
- **Actions**: 3×3 grid movements in X-Y plane

**`update_pos_27(x, y, z, s, action)`**
- **Purpose**: 27-action full 3D motion model
- **Actions**: 3×3×3 complete movement cube

## ⚙️ Configuration & Utilities

### Main Configuration

**`get_sim_settings()`**
- **Purpose**: Load all simulation parameters
- **Key Parameters**:
  ```matlab
  % Ocean environment
  s.OceanDepth = 40;           % Water depth [m]
  s.sim_frequency = 1000;      % Acoustic frequency [Hz]
  s.bottom_ssp = 1550;         % Bottom sound speed [m/s]
  
  % Parameter estimation
  s.mu_th = [1600; 1.5];       % Prior mean [speed; density]
  s.Sigma_th = diag([20, 0.1].^2);  % Prior covariance
  s.Sigma_rr = 1^2;            % Measurement noise variance
  
  % NBV planning
  s.sm = true;                 % Enable sensor management
  s.nbv_method = 'rrt_star_nbv';  % Planning algorithm
  s.depth = 3;                 % Planning horizon
  ```

**`default_settings()`**
- **Purpose**: Load optimized default configurations
- **Use**: Quick setup for different scenarios

### Utility Functions

**`startup()`**
- **Purpose**: Initialize project environment
- **Actions**: Add paths, check BELLHOP installation

**`clean_files(pattern)`**
- **Purpose**: Remove temporary BELLHOP files

## 🧪 Testing & Validation

### Validation Functions

**`validate_acoustic_model()`**
- **Purpose**: Comprehensive forward model validation
- **Tests**: Parameter ranges, numerical stability, physical behavior

**`test_parameter_estimation()`**
- **Purpose**: Monte Carlo validation of estimation accuracy
- **Tests**: Multiple scenarios, measurement counts, noise levels

**`benchmark_nbv_methods()`**
- **Purpose**: Compare NBV planning strategies
- **Metrics**: Speed, accuracy, path efficiency

## 🎮 Demo Functions

### Core Demonstrations

**`demo_parameter_estimation()`**
- **Purpose**: Basic bottom parameter estimation workflow
- **Shows**: Forward modeling, Bayesian estimation, NBV planning integration

**`demo_3d_acoustic_field(s)`**
- **Purpose**: Visualize 3D acoustic propagation
- **Shows**: Field variations, bottom parameter effects, spatial patterns

**`demo_adaptive_sensing()`**
- **Purpose**: Compare intelligent vs random sensor placement
- **Shows**: Strategy comparison, uncertainty reduction, performance metrics

## 🌍 Scenario Generation

### Environment Setup

**`scenarioBuilder(type, parameters)`**
- **Purpose**: Create ocean environment scenarios
- **Types**: Shallow water, deep ocean, variable bathymetry

**`generateFractalTerrain(size, roughness)`**
- **Purpose**: Generate realistic seafloor topography

**`uavScenarioBuilder(vehicle_type, constraints)`**
- **Purpose**: Setup vehicle-specific scenarios

## 📊 Data Analysis

### Visualization

**`plot_result(data, s)`**
- **Purpose**: Plot estimation results and measurement locations

**`plot_sound_speed_profile(source)`**
- **Purpose**: Visualize sound speed profiles from CTD data

### Results Processing

**`extractLeafData(tree)`**
- **Purpose**: Extract information from planning trees
- **Use**: Internal function for tree-based NBV methods

## 🔗 Integration Examples

### Complete Workflow
```matlab
% 1. Initialize
startup();
s = get_sim_settings();

% 2. Run parameter estimation
mission_main();

% 3. Validate results
validate_acoustic_model();
test_parameter_estimation();

% 4. Compare planning methods
benchmark_nbv_methods();
```

### Custom Estimation
```matlab
% Setup
s = get_sim_settings();
s.nbv_method = 'multi_objective';
s.N = 15;

% Initialize
data = init_filter(struct(), s);

% Estimation loop
for i = 1:s.N
    % Plan measurement
    data = pos_next_measurement_sota(data, s);
    
    % Get measurement (from real sensor or simulation)
    pos = [data.x(i+1), data.y(i+1), data.z(i+1)];
    measurement = get_acoustic_measurement(pos);  % Your sensor interface
    
    % Update estimate
    [data.th_est(:,i+1), data.Sigma_est(:,:,i+1)] = step_ukf_filter(...
        measurement, @(th)forward_model(th, pos, s), ...
        data.th_est(:,i), data.Sigma_est(:,:,i), s.Sigma_rr);
end
```

## 📚 Additional Resources

- **BELLHOP Documentation**: [Installation Guide](https://patel999jay.github.io/post/bellhop-acoustic-toolbox/)
- **NBV Optimization**: `docs/NBV_OPTIMIZATION_GUIDE.md`
- **Examples Directory**: `examples/` - Working demonstrations
- **Test Suite**: `tests/` - Validation and benchmarking
