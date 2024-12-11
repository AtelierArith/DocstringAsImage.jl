module DocstringAsImage

using Sixel
using FileIO, ImageIO
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
    mainfont: "Hiragino Mincho ProN"
    fontsize: "22pt"
---
"""

function issupported(x)::Bool
    return true
end

function issupported(m::Module)::Bool
    return Docs.hasdoc(m, nameof(m))
end

#@imgdoc sin
#@imgdoc Module
macro imgdoc(obj::Symbol)
    quote
        if !issupported($(esc(obj)))
            error(
                "Sorry, currently, DocstringAsImage does not support the Module which does not have docstring" *
                string($(esc(obj))) *
                " because Quarto may not compile the README.md correctly.",
            )
        end
        docstr = Docs.doc($(esc(obj)))
        imgdoc(docstr)
    end
end

#@imgdoc sin(1.0) should output the result of @imgdoc sin
macro imgdoc(obj::Expr)
    quote
        docstr = Docs.doc($(esc(obj.args[1])))
        imgdoc(docstr)
    end
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
    output_text = replace(output_text, r"^```jldoctest$"m => "```julia")
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
        end .|> load

    end

    for c in Iterators.partition(imgs, 2)
        Sixel.sixel_encode(hcat(c...))
    end
end

end # module DocstringAsImage
