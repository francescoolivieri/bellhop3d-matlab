# 🌊 Bellhop-3D MATLAB Abstraction Library

Bellhop3d-matlab wraps **BELLHOP3D** acoustic toolbox in a object-oriented MATLAB package (`+uw`).  It contains some examples of applications: **bottom-parameter and sound-speed-profile (SSP) estimation**, **informative path planning (IPP)** but can be used for general 3-D underwater propagation studies.

Note: the library was developed using the linux version of Bellhop-3D.

---
## ✨ Key Features

| Area | Highlights |
|------|------------|
| High-level API | Single façade class **`uw.Simulation`** to configure, run and visualise scenarios |
| Parameter management | **`uw.SimulationParameters`** (containers.Map wrapper) – default values from **`uw.SimSettings`** |
| Automatic file generation | Internal writers emit `.env`, `.bty`, `.ssp` files for BELLHOP3D |
| Namespaced code | MATLAB package isolation (`+uw`) – no global namespace pollution |

---
## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/francescoolivieri/bellhop3d-matlab.git,
   cd bellhop3d-matlab
   ```
2. **Install BELLHOP3D** and add it to your MATLAB path
   ```matlab
   addpath('/path/to/bellhop');   % adjust as needed
   ```
3. **Start MATLAB and initialise**
   ```matlab
   startup          % adds lib/ to path and checks BELLHOP
   ```
   MATLAB R2020b or newer is recommended.  The UKF example requires the *Statistics and Machine Learning Toolbox*.

---
## 🚀 Quick Start

```matlab
% 1.  Default parameters & flat seafloor scenario
params = uw.SimulationParameters.default();
sim    = uw.Simulation(params);

% 2.  Transmission loss at arbitrary receivers (x[km] y[km] z[m])
rx  = [0.5 0 20; 1 0 20];
TL  = sim.computeTL(rx);

% 3.  Visualise a TL slice (bearing index 1 by default)
sim.plotTLSlice();
```
> **Tip** `uw.Simulation` accepts a custom `scene` struct (fields `X`, `Y`, `floor`) if you want non-default bathymetry (`uw.SimSettings` has option to choose between flat, curves, gaussian features or fractal).

---
## 🔬 Scientific Workflows

### 1  Bottom-Parameter Estimation (UKF)
*Script: `examples/bottom_param_est/params_est_main.m`
1. Initialise simulation and prior.
2. Acquire noisy TL measurements.
3. Use Unscented-Kalman filter (examples/bottom_param_est/filtering`).
4. Optionally plan next measurement with IPP utilities.

### 2  SSP-Field Estimation (MCMC – *work-in-progress*)
*Script: `examples/ssp_estimation/ssp_est_main.m`*
1. Initialise SSPGaussianProcessMCMC class.
2. Acquire noisy TL measurements.
3. Metropolis-Hastings chain samples SSP grid consistent with TL data.
4. Optionally plan next measurement with IPP utilities. 

### 3  Sensor-Placement (IPP)
Algorithms in `uw.ipp_planning` pick next measurement point by information gain criteria. 

---
## 🗂️ Library Architecture (v0.3)
```
lib/+uw/
├── Simulation.m              % façade (run, visualise, computeTL)
├── SimulationParameters.m    % containers.Map wrapper
├── SimSettings.m             % default scalar settings
└── +internal/                % helpers
    ├── ForwardModel.m        % thin wrapper around BELLHOP3D
    ├── Visualization.m       % common plotting
    ├── +scenario/            % setup the bathymetry and altimetry environment
    └── +writers/             % writeENV3D/writeBTY3D/writeSSP3D
```
Legacy research code is retained in `src/` but will migrate into namespaced packages over time.

---
## 📊 Implemented Examples
| File | Description |
|------|-------------|
| `examples/params_est_main.m` | Bottom parameter estimation with UKF + IPP |
| `examples/ssp_est_main.m`    | Prototype SSP-grid estimation via MCMC (ongoing) |
| `examples/test.m`            | Minimal TL query demo |

Run any example after `startup` – they automatically add `lib` to the path.

---
## 🛣️ Future work
* Full GP-based SSP inversion example & ray-tracing visualiser
* Possibility to add multiple sources to the simulation
* Bellhop3D using Altimetry file
* Bathymetry more modulable (as of now if multiple types of sediment are present, the space is divided equally along the x axis)
* Test results in the real world


---
## 📄 Licence & Citation

If you use this library, cite as:
```bibtex
@software{bellhop3d-matlab,
  title        = {bellhop3d-matlab: Bellhop-3D MATLAB Abstraction Library},
  author       = {Francesco Olivieri},
  year         = {2025},
  url          = {https://github.com/francescoolivieri/bellhop3d-matlab.git},
  note         = {3-D acoustic propagation, Bayesian estimation, sensor planning}
}
```

---
**Feel free to propose and actively improve the repository.**
