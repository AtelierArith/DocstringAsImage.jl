# DocstringAsImage.jl

[![CI](https://github.com/AtelierArith/DocstringAsImage.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/AtelierArith/DocstringAsImage.jl/actions/workflows/CI.yml)

This package allows us to visualize Julia docstrings as images. This feature works only in terminals that support Sixel Graphics. Internally we use Quarto and Typst to render images. We use Sixel.jl package to render generated images in your terminal.

<img width="1131" alt="image" src="https://github.com/user-attachments/assets/96ceb5f8-fb10-443f-9512-73b8eb10eba9" />

## Setup

```
julia> using Pkg; Pkg.add("DocstringAsImage")
```

To build from source, run the following commands:

```sh
$ git clone https://github.com/AtelierArith/DocstringAsImage.jl.git
$ cd DocstringAsImage.jl
$ julia --project -e 'using Pkg; Pkg.instantiate()'
$ ls
Manifest.toml Project.toml  README.md     src
```

## Usage

Our package exports `@imgdoc` macro. It works like the `@doc` macro.

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
