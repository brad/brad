require 'octopress-hooks'

class PdfLatex < Octopress::Hooks::Page
  # Check if the pdf has a corresponding tex file, and if so compile it when needed
  def pre_render(page)
    if page.data['layout'] == 'pdf'
      pdf_file = page.content.split('/')[-1].strip()
      pdf_path = page.content.sub(pdf_file, '').strip()
      tex_file = pdf_file.sub('.pdf', '.tex')
      full_tex_path = ".#{pdf_path}#{tex_file}"
      if File.file?(full_tex_path)
        pdf_exists = File.file?(".#{pdf_path}#{pdf_file}")
        if not pdf_exists or File.lstat(full_tex_path).mtime > (Time.now - 2)
          # Compile the latex file
          cmd = "cd .#{pdf_path} && pdflatex -shell-escape #{tex_file}"
          system cmd
          if not pdf_exists
            # If this is the first time we've compiled the latex file, there will
            # be undefined references. Compiling again is necessary
            system cmd
          end
        end
      end
    end
  end
end
