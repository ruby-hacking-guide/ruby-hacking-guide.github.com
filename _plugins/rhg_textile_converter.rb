require "jekyll/converters/textile"
module Jekyll::Converters
  class RhgTextile < Textile
    safe true

    # set this :low before "jekyll serve" when you want to use only Jekyll::Converters::Textile
    priority :high

    RHG_CODE_RE = /`([^`]+)`/
    RHG_IMAGE_RE = /^!(.+\.(?:jpg|png))\((.+)\)!/

    def convert(content)
      # try to enable the <code> syntax of the original RubyForge project,
      # but not fully.
      lines = content.lines
      skips = []
      skips << "cvs diff parse.y" # chapter 11
      skips << "69      EXPR_DOT,      /*" # chapter 11
      content = lines.map do |line|
        unless skips.any? {|s| line.include? s }
          line = line.gsub(RHG_CODE_RE) { "<code>#{$1}</code>" }
        end

        # this applies the markup of the original book and
        # fixes improper markups of the generated htmls at the same time.
        if line =~ /^▼ /
          line = %{<p class="caption">#{line.rstrip}</p>\n}
        end

        line
      end.join

      # try to apply the style for images of the original book
      figc = 0
      no_figc = content.include? %{class="image"}
      content.gsub!(RHG_IMAGE_RE) do |m|
        figc += 1
        src, title = $~[1..2]
        alt = "(" +  src.split(".").first.split("_").last + ")"
        title = "Figure #{figc}: #{title}" unless no_figc
        out = <<-EOS
<p class="image">
<img src="#{src}" alt="#{alt}"><br>
#{title}
</p>
        EOS
      end

      super content
    end

    # simulate Jekyll::Converter.inherited
    Jekyll::Converter.subclasses << self
    Jekyll::Converter.subclasses.sort!
  end
end

