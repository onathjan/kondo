# Kondo: A Minimalist Static Site Generator

## Philosophy

Kondo is a **simple** and **opinionated** Static Site Generator designed to embrace minimalism. By prioritizing only the essentials, it pushes back against the complexity and bloat of modern websites, offering everything you need—and nothing you don’t—to create a clean and focused blog.

## Getting Started

1. Set up your config file.
2. Run bundle install to install gems. 
3. Set up commands:
    1. run `chmod +x bin/kondo` to make the scripts there executable
    2. run `./bin/kondo build` to build your site, `./bin/kondo serve` to serve the site, etc.
    3. (Optional but recommended) Add to your path to make commands global with `export PATH="$PATH:/path/to/your/kondo-project/bin"` and then running `source ~/.bash_profile  # or source ~/.zshrc if you're using zsh` so that you can run commands without the `./` in front of them (e.g. `kondo build`).


## Usage

kondo build    # Generate the static site
kondo serve    # Open the site locally in your default browser
kondo clean    # Removes files from site/ that have been deleted from content/
kondo new      # Create a new post or page
kondo deploy   # Deploy the site directory to your VPS with rsync
kondo help     # Show this help message

Notes:
kondo new post 'Title'   # Create a new post with a title
kondo new page 'Title'   # Create a new page with a title
Titles must be in single quotes or else you may run into dquote issues

---

# Kondo: A Minimalist Static Site Generator

## Philosophy

Kondo is a **simple** and **opinionated** Static Site Generator designed to embrace minimalism. By prioritizing only the essentials, it pushes back against the complexity and bloat of modern websites, offering everything you need—and nothing you don’t—to create a clean and focused blog.

## Installation

Before you start, ensure that you have Ruby and Bundler installed on your system.

1. Clone or download the Kondo repository to your local machine.
2. Run `bundle install` to install the necessary gems.
3. Set up commands:
  1. run `chmod +x bin/kondo` to make the scripts there executable
  2. run `./bin/kondo build` to build your site, `./bin/kondo serve` to serve the site, etc.
  3. (Optional but recommended) Add to your path to make commands global with `export PATH="$PATH:/path/to/your/kondo-project/bin"` and then running `source ~/.bash_profile  # or source ~/.zshrc if you're using zsh` so that you can run commands without the `./` in front of them (e.g. `kondo build`).

## Getting Started

1. Set up your config file (`config/config.yaml`).
2. Run `bundle install` to install the required gems.
3. Use the commands outlined below to build and serve your site.

## Usage

- `kondo build`    # Generate the static site
- `kondo serve`    # Serve the site locally in your default browser
- `kondo clean`    # Remove files from `site/` that have been deleted from `content/`
- `kondo new`      # Create a new post or page
- `kondo deploy`   # Deploy the site directory to your VPS with rsync
- `kondo help`     # Show this help message

### Creating New Posts or Pages

To create a new post or page, use the following commands:

- `kondo new post 'My First Post'`   # Create a new post with the title "My First Post"
- `kondo new page 'About Me'`        # Create a new page with the title "About Me"

**Note:** Titles should be enclosed in single quotes (e.g., `'My First Post'`) to avoid issues with quotes in the terminal.

## License

MIT License

Copyright (c) 2024 onathjan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

