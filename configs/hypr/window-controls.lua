-- Colors/buttons are generated from the same global semantic palette as the shell.
-- Loaded after each config reload, once the native plugin is available.
if hl.plugin.hyprbars and hl.plugin.hyprbars.clear_buttons then
    hl.config({plugin={hyprbars={
        bar_height=22, bar_text_size=9, bar_text_font="monospace",
        bar_text_align="left", bar_buttons_alignment="left",
        bar_padding=4, bar_button_padding=4, bar_blur=false,
        bar_part_of_window=true, bar_precedence_over_border=true,
        icon_on_hover=false,
        on_double_click=[[hyprctl eval 'hl.dispatch(hl.dsp.window.fullscreen({mode="maximized"}))']],
    }}})
    -- These windows already have matching compact controls built into their frame.
    hl.window_rule({name="susnix-terminal-native-controls",match={class="^susnix-terminal$"},["hyprbars:no_bar"]=true})
    hl.window_rule({name="susnix-files-native-controls",match={title="^Susnix Files$"},["hyprbars:no_bar"]=true})
    local palette_file=(os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME").."/.config").."/susnix/window-colors.lua"
    local apply=loadfile(palette_file)
    if apply then apply() end
end
