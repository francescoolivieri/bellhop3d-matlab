# API Reference – UnderwaterModeling3D

> Generated for library version 0.2.0  (TODO: bump when releasing)

## Package overview
| Package | Purpose |
|---------|---------|
| `uw` | Public API – façade & parameter classes |
| `uw.internal` | Writers, forward model, visualisation (subject to change) |
| `uw.gp_modeling` | Gaussian-process helpers for SSP field generation |

## 1. uw.SimulationParameters
```matlab
params = uw.SimulationParameters.default();
params.set('sound_speed_water',1490);
```
* Wraps a `containers.Map` internally
* Methods
  * `get(key)` / `set(key,val)`
  * `update(array,names)` – batch assign
  * `asArray(names)` – numeric vector for filters

## 2. uw.SimSettings
Static container that keeps **all** scalar simulation settings that BELLHOP expects (frequency, depth ranges, plotting options, …). You rarely need to touch this directly; a `uw.Simulation` object exposes and stores one instance internally.

## 3. uw.Simulation (main façade)
| Method | Description |
|--------|-------------|
| `computeTL(pos)` | Return transmission loss (dB) at receiver positions `pos [N×3]`. |
| `run(pos)` | Alias for `computeTL`. |
| `visualizeEnvironment()` | Plot SSP (or ENV) plus a TL slice. |
| *planned* `visualizeRays()` | 3-D ray tracing once implemented. |

Constructor forms:
```matlab
sim = uw.Simulation();                     % defaults everywhere
sim = uw.Simulation(params);               % custom parameters
sim = uw.Simulation(params, sceneStruct);  % custom bathymetry
```
`sceneStruct` must have fields `X`, `Y`, `floor` (bathymetry grid).

### Internal flow diagram
```mermaid
graph TD; A[Sim.computeTL]-->B[writeENV3D]; B-->C[BELLHOP3D]; C-->D[read_shd]; D-->E[interpolate TL];```

## 4. uw.gp_modeling.SSPGaussianProcess (experimental)
Creates 3-D Gaussian-process realisations of sound-speed profiles.
```matlab
sspGP = uw.gp_modeling.SSPGaussianProcess('lengthScale',500);
ssp   = sspGP.sampleField();   % Ny×Nx×Nz
```
Use the generated grid with `uw.internal.writers.writeSSP3D()` or inject directly into `params.set('ssp_grid', ssp)` (automatic `.ssp` writing will come soon).

## 5. Core internal helpers
* `uw.internal.ForwardModel.computeTL(simOrMap,pos)` – thin wrapper around BELLHOP.
* `uw.internal.writers.writeENV3D / writeBTY3D / writeSSP3D` – low-level file emitters.
* `uw.internal.Visualization.drawEnvironment` – shared plotting logic.

## Deprecated functions
All functions under `src/` remain for research reproducibility but will be removed in the next major release. Use the namespaced API instead.

## Changelog
* **0.2.0** – switch to package names, Simulation façade, docs refresh.
* **0.1.x** – initial research code.
