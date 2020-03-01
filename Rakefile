require "rake/clean"

CLOBBER.include FileList["*.pdf"]

MD_FILES = FileList["*.md"]
PDF_FILES = MD_FILES.map{|file| file.ext(".pdf") }

task :default => :pdf

multitask :pdf => PDF_FILES

rule ".pdf" => ".md" do |t|
  sh "pandoc", t.source,
     # Configure imput files.
     #   markdown : input is markdown
     #   ignore_line_breaks : ignore line brakes
     #   footnotes : use footnotes
     #   definition_lists : use definition list
     "-f", "markdown+ignore_line_breaks+footnotes+definition_lists",
     # Create title page.
     "-V", "titlepage=true",
     "-V", "titlepage-rule-color=53565a",
     # Numbering chapter.
     "-N",
     # Output Infomation.
     "-V", "CJKmainfont=IPAexGothic",
     # Table of Contents.
     "-V", "toc-own-page=true",
     "--table-of-contents", "--toc-depth=3",
     # Enable crossref.
     "-F", "pandoc-crossref",
     # Code highlighter and show line number.
     "--highlight-style", "tango",
     # Output format.
     "--pdf-engine=lualatex",
     "--template", "eisvogel",
     "-o", t.name
end

