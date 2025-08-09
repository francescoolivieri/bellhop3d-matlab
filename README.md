# 🌊 UnderwaterModeling3D – Bellhop-3D MATLAB Abstraction Library

UnderwaterModeling3D turns the FORTRAN-based **BELLHOP3D** acoustic toolbox into a modern, object-oriented MATLAB library that is easy to script, extend and embed in estimation pipelines.

Key features
-------------
* **High-level façade** `uw.Simulation` – one class to configure, run and visualise 3-D propagation scenarios.
* **Structured parameters** via `uw.SimulationParameters`; defaults provided by `uw.SimSettings`.
* **Internal writers** generate `.env`, `.bty`, `.ssp` files seamlessly.
* **Sound-Speed-Profile (SSP) field modelling** with Gaussian-process utilities (ongoing work).
* **Next-Best-View / Sensor-planning algorithms** ready for integration.
* MATLAB package namespace (`+uw`) isolates the public API – zero risk of name clashes.

Installation
------------
```matlab
% Inside project root
startup          % adds lib/ to path and checks BELLHOP
```
Requirements
* MATLAB R2020b+  (tested R2023b)
* BELLHOP / AcTUP 3-D  – download and add to path

Quick start
-----------
```matlab
params = uw.SimulationParameters.default();     % sane ocean & bottom
sim    = uw.Simulation(params);                % flat seafloor scenario

rx  = [0.5 0 20; 1.0 0 20];    % receiver positions [km km m]
TL  = sim.computeTL(rx);        % transmission-loss in dB

sim.visualizeEnvironment();     % plot SSP + TL slice
```

SSP field estimation (work-in-progress)
---------------------------------------
`uw.gp_modeling` provides Gaussian-process priors for 3-D SSP grids.  Example snippet:
```matlab
sspGP   = uw.gp_modeling.SSPGaussianProcess();   % define hyper-params
sspGrid = sspGP.sampleField();                   % Nx×Ny×Nz sound speed

uw.internal.writers.writeSSP3D("custom_ssp", x, y, z, sspGrid);
```
Integration with `uw.Simulation` will allow joint bathymetry + SSP estimation in upcoming releases.

Project layout (high-level)
---------------------------
```
lib/            +uw package (public API)
                 +uw.internal     (writers, forward model, viz)
examples/       runnable demos
src/            legacy research code (being ported)
docs/           detailed API reference
```

Roadmap
-------
* Ray tracing visualisation (sim.visualizeRays)
* Full MCMC SSP estimation workflow
* Python wrapper via MATLAB Engine
* CI tests on GitHub Actions

License
-------
Academic/non-commercial – see LICENSE file.
