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

#@imgdoc sin
#@imgdoc Module
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

#@imgdoc sin(1.0) should output the result of @imgdoc sin
macro imgdoc(obj::Expr)
    quote
        docstr = Docs.doc($(esc(obj.args[1])))
        imgdoc(docstr)
    end
end

function imgreadme(m::Module)
    readme = basename(REPL.find_readme(m))
    try
        imgs = mktempdir() do d
            cp(pkgdir(m), joinpath(d), force = true, follow_symlinks = true)
            readme = joinpath(d, readme)
            IOCapture.capture() do
                chmod(joinpath(d), 0o700, recursive = true)
                run(`$(quarto()) render $(readme) --to typst --metadata keep-typ:true`)
                typpath = first(splitext(readme)) * ".typ"
                @assert isfile(typpath)
                pngtemplate = joinpath(d, "sample_{n}.png")
                run(`$(quarto()) typst compile $(typpath) $(pngtemplate)`)
            end
            filter(readdir(d, join = true)) do f
                pattern = r"^sample_[0-9]+\.png$"
                m = match(pattern, basename(f))
                !isnothing(m)
            end .|> load
        end

        for c in Iterators.partition(imgs, 2)
            Sixel.sixel_encode(hcat(c...))
        end
    catch
        error("Sorry, Quarto can't render your $(basename(readme)) for $(m)")
    end
end

function todark(img::Matrix{RGBA{N0f8}})
    RGBA(1.0, 1.0, 1.0, 1.0) .- img .+ RGBA(0.0, 0.0, 0.0, 1.0)
end

function imgdoc(docstr)
    md = Markdown.MD(docstr)

    io = IOBuffer()
    println(io, frontmatter)

    for t in md.content
        println(io, t)
    end

    output_text = String(take!(io))
    # postprocess text
    output_text = replace(
        output_text,
        r"```math\s*(.*?)\s*```"m => s"$$\1$$",
        r"``(.*?)``" => s"$\1$",
    )
    output_text = replace(output_text, r"^```jldoctest.*$"m => "```julia")
    output_text = replace(output_text, r"^```julia-repl$"m => "```julia")
    imgs = mktempdir() do d
        qmdpath = joinpath(d, "sample.qmd")
        write(qmdpath, output_text)

        IOCapture.capture() do
            run(`$(quarto()) render $(qmdpath) --to typst`)
            typpath = joinpath(d, "sample.typ")
            @assert isfile(typpath)
            pngtemplate = joinpath(d, "sample_{n}.png")
            run(`$(quarto()) typst compile $(typpath) $(pngtemplate)`)
        end
        filter(readdir(d, join = true)) do f
            pattern = r"^sample_[0-9]+\.png$"
            m = match(pattern, basename(f))
            !isnothing(m)
        end .|> load .|> todark
    end

    for c in Iterators.partition(imgs, 2)
        Sixel.sixel_encode(hcat(c...))
    end
end

end # module DocstringAsImage
