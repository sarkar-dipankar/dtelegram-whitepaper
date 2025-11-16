# Makefile for dTelecom Whitepaper
# This Makefile automates the LaTeX compilation process

# Variables
LATEX = pdflatex
BIBTEX = bibtex
MAIN = main
OUTPUT = $(MAIN).pdf

# LaTeX flags
LATEXFLAGS = -interaction=nonstopmode -halt-on-error

# Auxiliary files to clean
AUX_FILES = *.aux *.log *.out *.toc *.bbl *.blg *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz

# Default target
.PHONY: all
all: pdf

# Build the PDF (full build with bibliography)
.PHONY: pdf
pdf: $(OUTPUT)

$(OUTPUT): $(MAIN).tex sample.bib
	@echo "==> First LaTeX pass..."
	$(LATEX) $(LATEXFLAGS) $(MAIN).tex
	@echo "==> Running BibTeX..."
	$(BIBTEX) $(MAIN)
	@echo "==> Second LaTeX pass..."
	$(LATEX) $(LATEXFLAGS) $(MAIN).tex
	@echo "==> Third LaTeX pass..."
	$(LATEX) $(LATEXFLAGS) $(MAIN).tex
	@echo "==> PDF generated successfully: $(OUTPUT)"

# Quick build (single pass, no bibliography update)
.PHONY: quick
quick:
	@echo "==> Quick build (single pass)..."
	$(LATEX) $(LATEXFLAGS) $(MAIN).tex
	@echo "==> Quick build complete: $(OUTPUT)"

# Clean auxiliary files
.PHONY: clean
clean:
	@echo "==> Cleaning auxiliary files..."
	rm -f $(AUX_FILES)
	@echo "==> Clean complete"

# Clean everything including the PDF
.PHONY: distclean
distclean: clean
	@echo "==> Removing PDF output..."
	rm -f $(OUTPUT)
	@echo "==> Distclean complete"

# View the PDF (Linux/macOS)
.PHONY: view
view: $(OUTPUT)
	@echo "==> Opening PDF..."
	@if command -v xdg-open > /dev/null 2>&1; then \
		xdg-open $(OUTPUT); \
	elif command -v open > /dev/null 2>&1; then \
		open $(OUTPUT); \
	elif command -v evince > /dev/null 2>&1; then \
		evince $(OUTPUT) & \
	else \
		echo "No suitable PDF viewer found. Please open $(OUTPUT) manually."; \
	fi

# Check if LaTeX is installed
.PHONY: check
check:
	@echo "==> Checking for required tools..."
	@command -v $(LATEX) >/dev/null 2>&1 || { echo "ERROR: pdflatex not found. Please install a LaTeX distribution."; exit 1; }
	@command -v $(BIBTEX) >/dev/null 2>&1 || { echo "ERROR: bibtex not found. Please install a LaTeX distribution."; exit 1; }
	@echo "==> All required tools are installed"

# Watch for changes and rebuild (requires inotify-tools on Linux or fswatch on macOS)
.PHONY: watch
watch:
	@echo "==> Watching for changes (press Ctrl+C to stop)..."
	@if command -v inotifywait > /dev/null 2>&1; then \
		while true; do \
			inotifywait -e modify $(MAIN).tex sample.bib *.png *.jpg 2>/dev/null; \
			make quick; \
		done \
	elif command -v fswatch > /dev/null 2>&1; then \
		fswatch -o $(MAIN).tex sample.bib *.png *.jpg | xargs -n1 -I{} make quick; \
	else \
		echo "ERROR: Neither inotifywait nor fswatch found. Install inotify-tools (Linux) or fswatch (macOS)."; \
		exit 1; \
	fi

# Spell check (requires aspell)
.PHONY: spell
spell:
	@echo "==> Running spell check..."
	@if command -v aspell > /dev/null 2>&1; then \
		aspell --lang=en --mode=tex check $(MAIN).tex; \
	else \
		echo "ERROR: aspell not found. Install it with: sudo apt-get install aspell"; \
		exit 1; \
	fi

# Count words in the document (requires texcount)
.PHONY: wordcount
wordcount:
	@echo "==> Counting words..."
	@if command -v texcount > /dev/null 2>&1; then \
		texcount -inc -incbib $(MAIN).tex; \
	else \
		echo "ERROR: texcount not found. Install it with: sudo apt-get install texlive-extra-utils"; \
		exit 1; \
	fi

# Archive the project
.PHONY: archive
archive: clean
	@echo "==> Creating archive..."
	@DATE=$$(date +%Y%m%d); \
	ARCHIVE="dtelecom-whitepaper-$$DATE.tar.gz"; \
	tar -czf ../$$ARCHIVE \
		--exclude='.git' \
		--exclude='*.tar.gz' \
		--exclude='*.zip' \
		.; \
	echo "==> Archive created: ../$$ARCHIVE"

# Display help
.PHONY: help
help:
	@echo "dTelecom Whitepaper - Makefile targets:"
	@echo ""
	@echo "  make          - Build the PDF (default)"
	@echo "  make pdf      - Build the PDF with full bibliography"
	@echo "  make quick    - Quick build (single pass, no bib update)"
	@echo "  make clean    - Remove auxiliary files"
	@echo "  make distclean- Remove all generated files including PDF"
	@echo "  make view     - Open the generated PDF"
	@echo "  make check    - Check if required tools are installed"
	@echo "  make watch    - Watch for changes and auto-rebuild"
	@echo "  make spell    - Run spell checker on main.tex"
	@echo "  make wordcount- Count words in the document"
	@echo "  make archive  - Create a tarball archive of the project"
	@echo "  make help     - Display this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make          # Build the whitepaper"
	@echo "  make view     # Build and open the PDF"
	@echo "  make clean pdf# Clean and rebuild from scratch"
	@echo ""
