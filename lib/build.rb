# 1. Load configuration:
#   - Read `config.yml` for site-wide settings (e.g., site name, base URL).

# 2. Prepare build environment:
#   - Clear out the `site/` directory if it exists.
#   - Recreate necessary subdirectories within `site/` (e.g., `assets/`).

# 3. Copy static assets:
#   - Copy files from the `assets/` directory into the `site/assets/` directory.

# 4. Generate pages:
#    - For each file in the `content/` directory:
#       a. Parse the file's front matter (metadata) and content.
#       b. Determine the output file path based on file location and type.
#       c. Render the content using the appropriate template from `templates/`.
#       d. Inject dynamic data (e.g., page title, metadata) into the template.
#       e. Save the rendered HTML file to the corresponding location in `site/`.

# 5. Generate index page:
#   - Use a specific template to render the site’s homepage/blog index (`content/index.md`) with relevant metadata.

# 6. Finalize:
#   - Output a success message indicating the build is complete.
#   - Optionally include a list of generated files or stats.
