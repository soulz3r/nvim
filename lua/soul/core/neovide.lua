local M = {}

function M.config()
    if not vim.g.neovide then
        return
    end

    vim.g.neovide_theme = "dark"
    vim.g.neovide_corner_preference = "round"
    vim.g.neovide_remember_window_size = true
    vim.g.neovide_confirm_quit = true

    vim.g.neovide_title_background_color = "#2D353B"
    vim.g.neovide_title_text_color = "#D3C6AA"

    vim.g.neovide_padding_top = 8
    vim.g.neovide_padding_bottom = 8
    vim.g.neovide_padding_left = 4
    vim.g.neovide_padding_right = 4

    vim.g.neovide_opacity = 0.97
    vim.g.neovide_normal_opacity = 1.0

    vim.g.neovide_floating_blur_amount_x = 2.5
    vim.g.neovide_floating_blur_amount_y = 2.5

    vim.g.neovide_floating_shadow = true
    vim.g.neovide_floating_z_height = 12
    vim.g.neovide_light_angle_degrees = 45
    vim.g.neovide_light_radius = 5

    vim.g.neovide_floating_corner_radius = 0.25

    vim.g.neovide_cursor_animation_length = 0.13
    vim.g.neovide_cursor_short_animation_length = 0.04
    vim.g.neovide_cursor_trail_size = 0.35

    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true
    vim.g.neovide_cursor_antialiasing = true

    vim.g.neovide_cursor_vfx_mode = ""

    vim.g.neovide_scroll_animation_length = 0.18
    vim.g.neovide_position_animation_length = 0.12
    vim.g.neovide_scroll_animation_far_lines = 1

    vim.g.neovide_refresh_rate = 75
    vim.g.neovide_refresh_rate_idle = 5

    vim.opt.guifont = "ComicShannsMono Nerd Font:h10"
end

return M
