# 🌊 UnderwaterModeling3D

**3D Underwater Acoustic Modeling for Bottom Parameters Estimation using Intelligent Sensor Networks**

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020b+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![Bellhop](https://img.shields.io/badge/Bellhop-Required-orange.svg)](https://patel999jay.github.io/post/bellhop-acoustic-toolbox/)
[![License](https://img.shields.io/badge/License-Academic-green.svg)]()

## 🎯 Overview

This project implements **Bayesian estimation of underwater bottom acoustic parameters** using **3D acoustic field modeling** and **intelligent sensor placement**. The system estimates critical bottom properties (sound speed, density, reflection coefficients) that are essential for:

- **🌊 Underwater Communication Systems**: Channel characterization and link budget analysis
- **🛡️ Naval Applications**: Sonar performance prediction and submarine detection
- **🔬 Marine Geophysics**: Seabed property mapping and geological surveys
- **🐋 Marine Biology**: Acoustic habitat characterization and species monitoring

## 🔬 Scientific Approach

### **Core Innovation: Bayesian Bottom Parameter Estimation**
The system estimates **bottom reflection parameters** (θ) using:

```
θ = [θ₁, θ₂]ᵀ where:
θ₁ ≈ Bottom sound speed [m/s]        (prior: 1600 ± 20 m/s)
θ₂ ≈ Bottom density/reflection factor (prior: 1.5 ± 0.1)
```

### **Methodology Pipeline:**

1. **🔊 3D Acoustic Forward Modeling** 
   - BELLHOP3D-based acoustic propagation simulation
   - Variable sound speed profiles and bathymetry
   - Realistic environmental conditions

2. **📊 Bayesian State Estimation**
   - Unscented Kalman Filter (UKF) for parameter tracking
   - Gaussian Process priors for spatial correlation
   - Uncertainty quantification and confidence bounds

3. **🚁 Intelligent Sensor Placement**
   - Next-Best-View (NBV) planning for optimal measurement locations
   - Multiple planning strategies (RRT*, information gain, multi-objective)
   - Vehicle-aware path planning for autonomous platforms

4. **⚙️ Real-time Implementation**
   - Efficient acoustic simulation with BELLHOP3D
   - Adaptive measurement strategies
   - Autonomous vehicle integration (drones, boats, AUVs)

## 🏗️ Project Structure

```
UnderwaterModeling3D/
├── 📁 src/                          # Core Implementation
│   ├── acoustic_modeling/           # 🔊 BELLHOP3D Integration & Forward Models
│   │   ├── forward_model.m          # Main acoustic simulation function
│   │   ├── prediction_error_loss.m  # Loss function for parameter estimation
│   │   └── bellhop_integration/     # BELLHOP file I/O and management
│   │
│   ├── filtering/                   # 📊 Bayesian Estimation (UKF)
│   │   ├── ukf.m                    # Unscented Kalman Filter
│   │   ├── step_ukf_filter.m        # UKF prediction/update step
│   │   └── unscented_transform.m    # UT for nonlinear transformations
│   │
│   ├── gp_modeling/                 # 🧠 Gaussian Process Sound Speed Models
│   │   ├── gen_sound_speed_gp.m     # GP-based sound speed field generation
│   │   └── spatial_correlation/     # Spatial modeling and interpolation
│   │
│   ├── nbv_planning/                # 🚁 Intelligent Sensor Placement  
│   │   ├── pos_next_measurement*.m  # NBV planning algorithms
│   │   ├── tree_methods/            # Tree-based planning (RRT, A*)
│   │   └── motion_models/           # Vehicle motion constraints
│   │
│   └── utils/                       # ⚙️ Core Utilities
│       ├── get_sim_settings.m       # Configuration management
│       └── file_io/                 # BELLHOP file handling
│
├── 📁 examples/                     # 🎮 Demos & Tutorials
│   ├── demo_parameter_estimation.m  # Basic bottom parameter estimation
│   ├── demo_3d_acoustic_field.m     # 3D acoustic field visualization
│   └── demo_adaptive_sensing.m      # Adaptive sensor placement
│
├── 📁 tests/                        # 🧪 Validation & Benchmarking
│   ├── validate_acoustic_model.m    # Forward model validation
│   ├── test_parameter_estimation.m  # Parameter estimation accuracy
│   └── benchmark_nbv_methods.m      # Sensor placement comparison
│
├── 📁 scenarios/                    # 🌍 Ocean Environments
│   ├── shallow_water/               # Coastal and shelf environments
│   ├── deep_ocean/                  # Abyssal and oceanic conditions
│   └── variable_bathymetry/         # Complex seafloor topography
│
├── 📁 data/                         # 📊 Input Datasets
│   ├── CTD.mat                      # Real oceanographic profiles
│   ├── bathymetry/                  # Seafloor elevation data
│   └── acoustic_measurements/       # Validation datasets
│
└── 📁 results/                      # �� Simulation Outputs
    ├── parameter_estimates/         # Bottom parameter results
    ├── acoustic_fields/             # 3D transmission loss fields
    └── uncertainty_maps/            # Estimation confidence regions
```

## 🚀 Quick Start

### Prerequisites

1. **MATLAB R2020b+** with toolboxes:
   - Statistics and Machine Learning Toolbox (for UKF)
   - Optimization Toolbox (for parameter estimation)
   - Signal Processing Toolbox (for acoustic processing)

2. **BELLHOP Acoustic Toolbox** - **REQUIRED**
   
   **📥 Download & Install**: [https://patel999jay.github.io/post/bellhop-acoustic-toolbox/](https://patel999jay.github.io/post/bellhop-acoustic-toolbox/)
   
   ⚠️ **Critical**: Add BELLHOP to MATLAB path after installation:
   ```matlab
   addpath('/path/to/bellhop/installation')  % Adjust path as needed
   ```

### Installation & Basic Usage

```matlab
% 1. Initialize project environment
startup  % Adds all paths and checks BELLHOP installation

% 2. Run basic bottom parameter estimation
mission_main  % Complete estimation workflow

% 3. Visualize 3D acoustic field  
s = get_sim_settings();
demo_3d_acoustic_field(s)

% 4. Try adaptive sensor placement
s.nbv_method = 'rrt_star_nbv';  % Optimal for vehicle platforms
data = pos_next_measurement_sota(data, s);
```

## 🔬 Core Algorithms

### **3D Acoustic Forward Model**

The forward model predicts transmission loss at any 3D position given bottom parameters:

```matlab
% θ = [bottom_sound_speed, bottom_density]
% pos = [x, y, z] measurement positions  
transmission_loss = forward_model(theta, pos, settings);
```

**Implementation:**
- Generates BELLHOP3D input files with current parameter estimates
- Runs full 3D acoustic propagation simulation
- Extracts transmission loss at sensor positions
- Handles variable sound speed profiles and complex bathymetry

### **Bayesian Parameter Estimation** 

Unscented Kalman Filter for real-time parameter tracking:

```matlab
% UKF prediction-update cycle
[theta_pred, Sigma_pred] = ukf_predict(theta, Sigma, process_noise);
[theta_est, Sigma_est] = ukf_update(theta_pred, Sigma_pred, measurement, forward_model);
```

**Features:**
- Handles nonlinear acoustic forward model
- Provides uncertainty quantification
- Adaptive to measurement noise and model errors
- Real-time compatible for autonomous systems

### **Intelligent Sensor Placement**

Multiple NBV strategies optimized for different platforms:

| Method | Best For | Key Advantage |
|--------|----------|---------------|
| `rrt_star_nbv` | **Autonomous vehicles** | Optimal paths with vehicle constraints |
| `information_gain` | **Static sensors** | Direct information optimization |
| `multi_objective` | **Mission planning** | Balances multiple objectives |
| `uncertainty_guided` | **GP-based modeling** | Leverages spatial correlations |

## 📊 Scientific Validation

### **Acoustic Model Validation**
```matlab
validate_acoustic_model()  % Compare with analytical solutions
```

### **Parameter Estimation Accuracy**
```matlab
test_parameter_estimation()  % Monte Carlo validation studies
```

### **Sensor Placement Performance**
```matlab
benchmark_nbv_methods()  % Comprehensive performance comparison
```

## 🌊 Applications & Use Cases

### **Underwater Communication Systems**
- **Channel Characterization**: Predict communication performance
- **Link Budget Analysis**: Estimate range and reliability
- **Network Deployment**: Optimal node placement strategies

```matlab
% Example: Communication channel analysis
s = get_sim_settings();
s.sim_frequency = 25000;  % 25 kHz communication frequency
s.bottom_type = 'sandy';  % Sandy bottom environment
[theta_est, uncertainty] = estimate_bottom_parameters(s);
channel_performance = predict_communication_range(theta_est, s);
```

### **Naval & Defense Applications**
- **Sonar Performance**: Bottom loss modeling for active sonar
- **ASW Operations**: Submarine detection probability maps
- **Mine Warfare**: Acoustic signature modeling

### **Marine Geophysics**
- **Seabed Classification**: Automated bottom type identification  
- **Geological Surveys**: Sub-bottom parameter mapping
- **Resource Exploration**: Acoustic impedance estimation

### **Environmental Monitoring**
- **Habitat Mapping**: Acoustic characterization of marine environments
- **Climate Studies**: Long-term bottom property changes
- **Ecosystem Assessment**: Benthic community habitat quality

## ⚙️ Configuration

### **Ocean Environment Settings**
```matlab
s = get_sim_settings();

% Ocean properties
s.OceanDepth = 40;           % Water depth [m]
s.sim_frequency = 1000;      % Acoustic frequency [Hz]
s.bottom_ssp = 1550;         % Bottom sound speed [m/s]

% Bottom parameter priors
s.mu_th = [1600; 1.5];       % [sound speed; density] prior mean
s.Sigma_th = diag([20, 0.1].^2);  % Prior covariance
```

### **Estimation Parameters**
```matlab
% Measurement settings
s.N = 15;                    % Number of measurements
s.sigma_tl_noise = 1;        % Measurement noise [dB]
s.Sigma_rr = 1^2;           % Filter noise assumption

% NBV planning
s.nbv_method = 'rrt_star_nbv';  % Planning algorithm
s.depth = 3;                    % Planning horizon [steps]
```

## 🧪 Advanced Examples

### **Multi-Frequency Analysis**
```matlab
frequencies = [100, 500, 1000, 5000];  % Hz
for f = frequencies
    s.sim_frequency = f;
    [theta_est(f), confidence(f)] = run_parameter_estimation(s);
end
analyze_frequency_dependence(theta_est, confidence);
```

### **Adaptive Measurement Campaign**
```matlab
% Autonomous underwater vehicle survey
s.vehicle_type = 'auv';
s.nbv_method = 'multi_objective';
s.mission_duration = 3600;  % seconds
results = run_adaptive_survey(s);
```

### **Real-time Processing**
```matlab
% Stream processing for real-time estimation
data_stream = initialize_measurement_stream();
while data_stream.has_data()
    measurement = data_stream.get_next();
    [theta, Sigma] = update_parameter_estimate(theta, Sigma, measurement);
    next_position = plan_next_measurement(theta, Sigma, s);
    send_vehicle_command(next_position);
end
```

## 🔧 Development & Extension

### **Adding New Bottom Models**
1. Extend `forward_model.m` with new parameter types
2. Update prior distributions in `get_sim_settings.m`
3. Modify BELLHOP input generation in `writeENV3D.m`

### **Custom Acoustic Environments** 
1. Create scenario in `scenarios/`
2. Define bathymetry and sound speed profiles
3. Set appropriate boundary conditions

### **New Sensor Platforms**
1. Define motion constraints in `motion_models/`
2. Implement platform-specific NBV planning
3. Add vehicle dynamics if needed

## 📚 Documentation

- **[NBV Planning Guide](docs/NBV_OPTIMIZATION_GUIDE.md)**: Detailed sensor placement strategies
- **[API Reference](docs/API_REFERENCE.md)**: Function documentation
- **Parameter Estimation Theory**: Mathematical foundations and derivations
- **BELLHOP Integration Guide**: Advanced acoustic modeling setup

## 🐛 Troubleshooting

### **Common Issues**

1. **BELLHOP Installation Problems**:
   ```bash
   # Linux/Mac
   cd bellhop/installation/directory
   make clean && make all
   ```

2. **Parameter Estimation Convergence**:
   ```matlab
   % Adjust prior uncertainty
   s.Sigma_th = diag([50, 0.5].^2);  % Increase uncertainty
   
   % Reduce measurement noise assumption  
   s.Sigma_rr = 0.5^2;
   ```

3. **Acoustic Simulation Errors**:
   - Check frequency range (recommended: 100-10000 Hz)
   - Verify bathymetry bounds and resolution
   - Ensure sound speed profile consistency

## 📄 Citation

If you use this work in research, please cite:

```bibtex
@software{underwater_modeling_3d,
  title={3D Underwater Acoustic Modeling for Bottom Parameters Estimation},
  author={[Author Names]},
  year={2024},
  note={Advanced Bayesian estimation using BELLHOP3D and intelligent sensor networks},
  url={https://github.com/[repo]/UnderwaterModeling3D}
}
```

## 🤝 Contributing

We welcome contributions in:
- **New parameter estimation algorithms** (Extended Kalman Filter, Particle Filter)
- **Advanced acoustic models** (Parabolic equation, normal modes)  
- **Real-world validation datasets** (Measured acoustic data)
- **Platform integrations** (ROS, specific vehicle types)

## 🔗 References

- **BELLHOP Documentation**: [Acoustic Toolbox Guide](https://patel999jay.github.io/post/bellhop-acoustic-toolbox/)
- **Underwater Acoustics**: Jensen et al., "Computational Ocean Acoustics"
- **Bayesian Estimation**: Simon, "Optimal State Estimation"
- **Active Sensing**: Krause & Guestrin, "Near-optimal Sensor Placements"

---

**🌊 Advancing underwater acoustic science through intelligent parameter estimation! 🔬**
