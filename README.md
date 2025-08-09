# 🌊 UnderwaterModeling3D – Bellhop-3D MATLAB Abstraction Library

UnderwaterModeling3D wraps the FORTRAN-based **BELLHOP3D** acoustic toolbox in a modern, object-oriented MATLAB package (`+uw`).  It is built for research on **bottom-parameter and sound-speed-profile (SSP) estimation**, **intelligent sensor placement (NBV)** and general 3-D underwater propagation studies.

---
## ✨ Key Features

| Area | Highlights |
|------|------------|
| High-level API | Single façade class **`uw.Simulation`** to configure, run and visualise scenarios |
| Parameter management | **`uw.SimulationParameters`** (containers.Map wrapper) – default values from **`uw.SimSettings`** |
| Automatic file generation | Internal writers emit `.env`, `.bty`, `.ssp` files for BELLHOP3D |
| SSP field modelling | Gaussian-process utilities (`uw.gp_modeling`) – *in active development* |
| NBV planning | Hooks for RRT*, information-gain and multi-objective planners (`uw.nbv_planning`) |
| Namespaced code | MATLAB package isolation (`+uw`) – no global namespace pollution |

---
## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/<org>/UnderwaterModeling3D.git
   cd UnderwaterModeling3D
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

% 3.  Visualise SSP grid + TL slice
sim.visualizeEnvironment();
```
> **Tip** `uw.Simulation` accepts a custom `scene` struct (fields `X`, `Y`, `floor`) if you want non-default bathymetry.

---
## 🔬 Scientific Workflows

### 1  Bottom-Parameter Estimation (UKF)
*Scripts: `examples/params_est_main.m`, `tests/batch_param_est.m`*
1. Initialise simulation and prior.
2. Acquire TL measurements (real sensor or simulated).
3. Use Unscented-Kalman filter (`src/filtering`) with `sim.computeTL` as the forward model.
4. Optionally plan next measurement with NBV utilities.

### 2  SSP-Field Estimation (MCMC – *work-in-progress*)
*Script: `examples/ssp_est_mcmc.m`*
1. GP prior (`uw.gp_modeling.SSPGaussianProcess`).
2. Metropolis-Hastings chain samples SSP grid consistent with TL data.
3. Planned release: v0.4.

### 3  Sensor-Placement (NBV)
Algorithms in `uw.nbv_planning` pick next measurement point by information gain, RRT* or multi-objective criteria.  See `examples/nbv_planning_*` for usage.

---
## 🗂️ Library Architecture (v0.3)
```
lib/+uw/
├── Simulation.m              % façade (run, visualise, computeTL)
├── SimulationParameters.m    % containers.Map wrapper
├── SimSettings.m             % default scalar settings
├── +internal/                % helpers (subject to change)
│   ├── ForwardModel.m        % thin wrapper around BELLHOP3D
│   ├── Visualization.m       % common plotting
│   └── +writers/             % writeENV3D/writeBTY3D/writeSSP3D
└── +gp_modeling/ (WIP)       % GP utilities
```
Legacy research code is retained in `src/` but will migrate into namespaced packages over time.

---
## 📊 Implemented Examples
| File | Description |
|------|-------------|
| `examples/params_est_main.m` | Bottom parameter estimation with UKF + NBV planning |
| `examples/ssp_est_mcmc.m`    | Prototype SSP-grid estimation via MCMC (ongoing) |
| `examples/test.m`            | Minimal TL query demo |

Run any example after `startup` – they automatically add `lib` to the path.

---
## 🛣️ Roadmap
* 0.4 – Full GP-based SSP inversion example & ray-tracing visualiser (`sim.visualizeRays`)
* 0.5 – Namespacing of all remaining `src/` modules
* 0.6 – Python bindings via MATLAB Engine, CI test-suite

---
## 📄 Licence & Citation
Academic/non-commercial – see LICENSE.

If you use this library, cite as:
```bibtex
@software{underwater_modeling_3d,
  title        = {UnderwaterModeling3D: Bellhop-3D MATLAB Abstraction Library},
  author       = {<Authors>},
  year         = {2024},
  url          = {https://github.com/<org>/UnderwaterModeling3D},
  note         = {3-D acoustic propagation, Bayesian estimation, sensor planning}
}
```

---
**Advancing underwater acoustics through open, extensible tooling.**
