[![Build Status](https://github.com/bubbobne/GEOFRAMEjl.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bubbobne/GEOFRAMEjl.jl/actions/workflows/CI.yml?query=branch%3Amain)

# GEOFRAMEjl

![Julia](https://img.shields.io/badge/-Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)


`GEOFRAMEjl` is a Julia package designed to interact with GEOframe. It offers tools for reading GEOframe output files, evaluating goodness of fit, and preparing data.

## Installation
***

As this packages is not yet publisched, you can install stable version of `GEOFRAMEjl` from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/bubbobne/GEOFRAMEjl.jl", rev="main")
```



## Features
***

### **CSV Handling**: 
Read and parse CSV files designed for GEOframe use.

```julia
using GEOFRAMEjl
t = GFIO.read_OMS_timeserie("your_scv.csv")
GFIO.write_OMS_timeserie(t, "your_scv.csv")
```

### **Goodnes of fit metrics**: 

Each metrics has two function, one for arrays and other for TimeSeries. The latter end with `_ts` (e.g. kge() amd kge_ts()).
The following metrics are implemented:

* Kling-Gupta Efficiency, kge
* Nash-Sutcliffe Efficiency, nse  also available in logarithmic form (ns_log)
* Mean Squared Error, mse



```julia
using GEOFRAMEjl
using TimeSeries, Dates

timestamps = DateTime(2020, 1, 1):Day(1):DateTime(2020, 1, 5)
observed_values = [1.0, 2.0, 3.0, 4.0, 5.0]
simulated_values = [1.1, 1.9, 3.05, 3.95, 5.1]
observed_ta = TimeArray(timestamps, observed_values)
simulated_ta = TimeArray(timestamps, simulated_values)
GOF.kge_ts(observed_ta, simulated_ta, false, n_min=2)


```


### **Spatial Grid Generation**: 

Create grids with customizable dimensions.


```julia
using GEOFRAMEjl

a =Geo.create_grid(614100,680300,500,5112800,5159000,500)
save_grid(a,"./grid_kriging/grid.shp", 32632)

```




## Contributing
***

Contributions to `GEOFRAMEjl` are welcome! Here are ways you can contribute:

- Submit bug reports and feature requests.
- Review the code and provide feedback.
- Submit pull requests to help fix bugs or add features.

For more information, see our [Community Publication Policy](http://geoframe.blogspot.com/2020/05/geoframe-community-publication-policy.html).



## License
***

`GEOFRAMEjl` is GPL3 licensed, as found in the [LICENSE](LICENSE) file.


## Contact
***

For questions and support, please contact us via email at [??????????](mailto:contact@???).


