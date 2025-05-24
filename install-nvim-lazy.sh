#!/bin/bash

# Neovim + Lazy.nvim Installation Script for WSL2
# Usage: ./install-nvim-lazy.sh
# 
# This script:
# 1. Removes old neovim
# 2. Installs latest neovim via tarball
# 3. Sets up lazy.nvim bootstrap
# 4. Optionally stows dotfiles if available

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NVIM_VERSION="v0.11.1"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
INSTALL_DIR="/opt"
BIN_DIR="/usr/local/bin"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in WSL2
check_wsl2() {
    if ! grep -q microsoft /proc/version; then
        log_warning "This script is designed for WSL2, but continuing anyway..."
    else
        log_info "WSL2 detected ✓"
    fi
}

# Remove old neovim installations
remove_old_nvim() {
    log_info "Removing old neovim installations..."
    
    # Remove apt package
    if command -v apt >/dev/null 2>&1; then
        sudo apt remove -y neovim 2>/dev/null || true
    fi
    
    # Remove old symlinks
    sudo rm -f "${BIN_DIR}/nvim"
    
    # Remove old installations
    sudo rm -rf "${INSTALL_DIR}/nvim-linux64"
    sudo rm -rf "${INSTALL_DIR}/nvim-linux-x86_64"
    sudo rm -rf "${INSTALL_DIR}/nvim-appimage"
    
    log_success "Old installations removed"
}

# Download and install neovim
install_neovim() {
    log_info "Downloading Neovim ${NVIM_VERSION}..."
    
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download with progress bar
    curl -L --progress-bar -o nvim-linux-x86_64.tar.gz "$NVIM_URL"
    
    log_info "Installing to ${INSTALL_DIR}..."
    sudo tar -C "$INSTALL_DIR" -xzf nvim-linux-x86_64.tar.gz
    
    # Create symlink
    sudo ln -sf "${INSTALL_DIR}/nvim-linux-x86_64/bin/nvim" "${BIN_DIR}/nvim"
    
    # Cleanup
    cd - >/dev/null
    rm -rf "$temp_dir"
    
    log_success "Neovim installed successfully"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    if ! command -v nvim >/dev/null 2>&1; then
        log_error "nvim command not found in PATH"
        return 1
    fi
    
    local version
    version=$(nvim --version | head -n1)
    log_success "Installed: $version"
    
    # Check if it's the expected version
    if [[ "$version" == *"${NVIM_VERSION}"* ]]; then
        log_success "Version matches expected ${NVIM_VERSION}"
    else
        log_warning "Version mismatch. Expected ${NVIM_VERSION}, got: $version"
    fi
}

# Setup lazy.nvim bootstrap
setup_lazy_nvim() {
    log_info "Setting up lazy.nvim bootstrap configuration..."
    
    local nvim_config_dir="$HOME/.config/nvim"
    local dotfiles_nvim="$HOME/dotfiles/nvim/.config/nvim"
    
    # Check if dotfiles nvim config exists
    if [[ -d "$dotfiles_nvim" ]]; then
        log_info "Found existing dotfiles nvim config, using that..."
        
        # Ensure proper stow structure exists
        if [[ -f "$dotfiles_nvim/init.lua" ]]; then
            log_success "Dotfiles nvim config looks good"
            return 0
        else
            log_warning "Dotfiles nvim config incomplete, creating bootstrap..."
        fi
    fi
    
    # Create directories
    mkdir -p "${nvim_config_dir}/lua/config"
    mkdir -p "${nvim_config_dir}/lua/plugins"
    
    # Create init.lua
    cat > "${nvim_config_dir}/init.lua" << 'EOF'
-- Bootstrap lazy.nvim
require("config.lazy")
EOF
    
    # Create config/lazy.lua
    cat > "${nvim_config_dir}/lua/config/lazy.lua" << 'EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- Import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true },
})
EOF
    
    # Create example plugin
    cat > "${nvim_config_dir}/lua/plugins/example.lua" << 'EOF'
return {
  -- Which-key for keybinding help
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup()
    end,
  },
  
  -- Better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "javascript", "bash", "json", "yaml" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  
  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>')
    end,
  },
}
EOF
    
    log_success "Lazy.nvim bootstrap configuration created"
}

# Integrate with dotfiles if available
integrate_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    
    if [[ ! -d "$dotfiles_dir" ]]; then
        log_info "No dotfiles directory found, skipping integration"
        return 0
    fi
    
    log_info "Integrating with existing dotfiles..."
    
    # Check if stow is available
    if ! command -v stow >/dev/null 2>&1; then
        log_warning "GNU Stow not found. Install with: sudo apt install stow"
        return 0
    fi
    
    local nvim_config_dir="$HOME/.config/nvim"
    local dotfiles_nvim="$dotfiles_dir/nvim/.config/nvim"
    
    # If nvim config was just created and dotfiles nvim doesn't exist
    if [[ -d "$nvim_config_dir" ]] && [[ ! -d "$dotfiles_nvim" ]]; then
        log_info "Moving nvim config to dotfiles..."
        
        # Create dotfiles nvim structure
        mkdir -p "$dotfiles_dir/nvim/.config"
        mv "$nvim_config_dir" "$dotfiles_nvim"
        
        # Stow it back
        cd "$dotfiles_dir"
        stow nvim
        
        log_success "Nvim config moved to dotfiles and stowed"
    elif [[ -d "$dotfiles_nvim" ]]; then
        log_info "Using existing dotfiles nvim config..."
        
        # Remove any existing config and stow from dotfiles
        rm -rf "$nvim_config_dir"
        cd "$dotfiles_dir"
        stow nvim
        
        log_success "Dotfiles nvim config stowed"
    fi
}

# Run health check
run_health_check() {
    log_info "Running neovim health check..."
    
    # Run in background to avoid hanging
    timeout 30s nvim --headless -c 'checkhealth lazy' -c 'qall' 2>/dev/null || {
        log_warning "Health check timed out or failed (this is normal on first run)"
    }
    
    log_info "Health check complete. Run ':checkhealth' in nvim for detailed results"
}

# Main installation flow
main() {
    echo "🚀 Neovim + Lazy.nvim Installation Script"
    echo "========================================"
    
    check_wsl2
    remove_old_nvim
    install_neovim
    verify_installation
    setup_lazy_nvim
    integrate_dotfiles
    
    log_success "🎉 Installation complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Run 'nvim' to start and let lazy.nvim install plugins"
    echo "  2. Use ':Lazy' to manage plugins"
    echo "  3. Use ':checkhealth' to verify everything is working"
    echo "  4. Add your plugins to ~/.config/nvim/lua/plugins/"
    echo ""
    log_info "Enjoy your new Neovim setup! ✨"
}

# Run the script
main "$@"
