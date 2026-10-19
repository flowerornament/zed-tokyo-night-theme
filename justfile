tokyonight := env("TOKYONIGHT", home_directory() / ".local/share/nvim/site/pack/core/opt/tokyonight.nvim")

# Regenerate themes/tokyonight.json from tokyonight.nvim
build:
    nvim --clean -l generate.lua {{tokyonight}} themes/tokyonight.json

# Build and copy into Zed's user themes (Zed did not pick up a symlink)
install: build
    cp themes/tokyonight.json {{home_directory()}}/.config/zed/themes/tokyonight.json

# Re-render screenshots/*.png in a background Zed instance
screenshots:
    screenshot/capture.sh
