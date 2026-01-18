FROM python:3.12-slim

# Install RenderCV
RUN pip install rendercv[full]

# Set working directory
WORKDIR /cv

# Default command
CMD [rendercv, --help]
