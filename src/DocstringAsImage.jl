module DocstringAsImage

using Sixel
using FileIO, ImageIO, ImageCore
using Markdown
using quarto_jll
import REPL # Required to collect all docstrings
using IOCapture: IOCapture

export @imgdoc

frontmatter = """
---
format:
  typst:
    keep-typ: true
    margin:
      x: 2cm
      y: 2cm
    #mainfont: "Hiragino Mincho ProN"
    fontsize: "22pt"
---
"""

"""
    @imgdoc expr

Generate and display images from the docstring of a given Julia symbol.

This macro processes the docstring of the specified symbol to generate images,
converts them to a dark color space, and then encodes them for display.
"""
macro imgdoc(s::Symbol)
    obj = esc(s)
    quote
        docstr = if $(obj) isa Module
            local m = $(obj)
            if Docs.hasdoc(m, nameof(m))
                imgdoc(Docs.doc(m))
            else
                r = REPL.find_readme(m)
                if isnothing(r)
                    error(
                        "Sorry, currently, DocstringAsImage does not support the" *
                        " @doc " *
                        string(m) *
                        " because it has not docstring nor README.md.",
                    )
                else
                    imgreadme(m)
                end
            end
        else
            docstr = Docs.doc($(obj))
            imgdoc(docstr)
        end
    end
end

macro imgdoc(obj::Expr)
    quote
        docstr = Docs.doc($(esc(obj.args[1])))
        imgdoc(docstr)
    end
end


"""
    todark(img)

Convert an image from RGB color space to dark color space.

Args:
    img (Matrix{RGBA{N0f8}}): An image represented as a Matrix of RGBA colors.
"""
function todark(img::Matrix{RGBA{N0f8}})
    RGBA(1.0, 1.0, 1.0, 1.0) .- img .+ RGBA(0.0, 0.0, 0.0, 1.0)
end

"""
    module2images(m::Module, d::String)

Generate images from the README file of a given Julia module.

Copies the module's directory to a specified location, processes the README file
to generate images, and returns these images.

# Arguments
- `m::Module`: The Julia module whose README file will be processed.
- `d::String`: The directory path where the module's files will be copied and images will be saved.

# Returns
- `Vector{Matrix{RGBA{N0f8}}}`: A vector of images generated from the module's README file.
"""
function module2images(m::Module, d::String)
    cp(pkgdir(m), joinpath(d), force = true, follow_symlinks = true)
    readme = basename(REPL.find_readme(m))
    readme = joinpath(d, readme)
    IOCapture.capture() do
        chmod(joinpath(d), 0o700, recursive = true)
        run(`$(quarto()) render $(readme) --to typst --metadata keep-typ:true`)
        typpath = first(splitext(readme)) * ".typ"
        @assert isfile(typpath)
        pngtemplate = joinpath(d, "sample_{n}.png")
        run(`$(quarto()) typst compile $(typpath) $(pngtemplate)`)
    end
    images = filter(readdir(d, join = true)) do f
        pattern = r"^sample_[0-9]+\.png$"
        m = match(pattern, basename(f))
        !isnothing(m)
    end .|> load
    return images
end

"""
    preprocess_text4typst(output_text::String)

Process Julia docstring so that Typst can process it.

Args:
    output_text (String): A Julia docstring.

Returns:
    String: Processed Julia docstring.

Notes:

- Treat math block as LaTeX
- Treat jldoctest block as julia code
- Treat julia-repl session as julia code
"""
function preprocess_text4typst(output_text::String)
    # treat math block as LaTeX
    output_text = replace(
        output_text,
        r"```math\s*(.*?)\s*```"m => s"$$\1$$",
        r"``(.*?)``" => s"$\1$",
    )
    # treat jldoctest block as julia code
    output_text = replace(output_text, r"^```jldoctest.*$"m => "```julia")
    # treat julia-repl session as julia code
    output_text = replace(output_text, r"^```julia-repl$"m => "```julia")
    return output_text
end


"""
    text2images(text::String, d::String)

Generate images from text contains Julia docstring.

Args:
    d (String): The directory path to save images.

Returns:
    Vector{Matrix{RGBA{N0f8}}}: A vector of images.

Notes:
"""
function text2images(text::String, d::String)
    qmdpath = joinpath(d, "sample.qmd")
    write(qmdpath, text)

    IOCapture.capture() do
        run(`$(quarto()) render $(qmdpath) --to typst`)
        typpath = joinpath(d, "sample.typ")
        @assert isfile(typpath)
        pngtemplate = joinpath(d, "sample_{n}.png")
        run(`$(quarto()) typst compile $(typpath) $(pngtemplate)`)
    end
    images = filter(readdir(d, join = true)) do f
        pattern = r"^sample_[0-9]+\.png$"
        m = match(pattern, basename(f))
        !isnothing(m)
    end .|> load
    return images
end

"""
    imgreadme(m::Module)

Generate and display images from the README file of a given Julia module.

This function processes the README file of the specified module to generate images,
converts them to a dark color space, and then encodes them for display.

# Arguments
- `m::Module`: The Julia module whose README file will be processed.

# Returns
- `Nothing`: This function does not return a value. It performs its operations for side effects.
"""
function imgreadme(m::Module)
    try
        imgs = mktempdir() do d
            module2images(m, d)
        end
        imgs = todark.(imgs)
        for c in Iterators.partition(imgs, 2)
            Sixel.sixel_encode(hcat(c...))
        end
    catch
        error("Sorry, Quarto can't render your $(basename(readme)) for $(m)")
    end
end


"""
    imgdoc(docstr)

Generate and display images from a given Julia docstring.

This function processes a Julia docstring to generate images, converts them to a dark color space,
and then encodes them for display.

# Arguments
- `docstr::String`: The Julia docstring to be processed.

# Returns
- `Nothing`: This function does not return a value. It performs its operations for side effects.
"""
function imgdoc(docstr)
    md = Markdown.MD(docstr)

    io = IOBuffer()
    println(io, frontmatter)

    for t in md.content
        println(io, t)
    end

    output_text = String(take!(io))
    output_text = preprocess_text4typst(output_text)

    imgs = mktempdir() do d
        text2images(output_text, d)
    end
    if !isempty(imgs)
        imgs = todark.(imgs)
    end
    for c in Iterators.partition(imgs, 2)
        Sixel.sixel_encode(hcat(c...))
    end
end

end # module DocstringAsImage
