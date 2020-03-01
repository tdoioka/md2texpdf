require "rake/clean"

MD_FILES = FileList["*.md"]
PDF_FILES = MD_FILES.map{|file| file.ext(".pdf") }

task :default => :pdf

task :pdf => PDF_FILES

rule ".pdf" => ".md" do |t|
  sh "pandoc", t.source,
     # Configure imput files.
     #   markdown : input is markdown
     #   ignore_line_breaks : ignore line brakes
     #   footnotes : use footnotes
     #   definition_lists : use definition list
     "-f", "markdown+ignore_line_breaks+footnotes+definition_lists",
     # Create Title page
     "-V", "classoption=titlepage",
     # Setting of Table of Contents. 
     "--table-of-contents", "--toc-depth=3",
     # Numbering chapters and sections.
     "-N", 
     # Configure TEX to output Japanese.
     "--pdf-engine=lualatex",
     "-V", "documentclass=bxjsarticle",
     "-V", "classoption=pandoc",
     "-o", t.name
end

