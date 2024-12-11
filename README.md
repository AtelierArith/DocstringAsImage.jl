# DocstringAsImage.jl

This package visualizes Julia docstrings for functions with images.

## Setup

```sh
$ git clone https://github.com/AtelierArith/DocstringAsImage.jl.git
$ cd DocstringAsImage.jl
$ julia --project -e 'using Pkg; Pkg.instantiate()'
$ ls
Manifest.toml Project.toml  README.md     src
```

## Usage

```julia
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.11.2 (2024-12-01)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org/ release
|__/                   |

julia> using DocstringAsImage
julia> @imgdoc exp
julia> using SpecialFunctions: zeta
julia> @imgdoc zeta
julia> using Distributions: Beta
julia> @imgdoc Beta
```
