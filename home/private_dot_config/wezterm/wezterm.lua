-- Windows 上の WezTerm の設定。
-- WSL 上の tmux で用いていた操作と表示を、WezTerm のタブ、ペイン、タブバーへ対応付ける。
-- ペインヘッダやペイン一覧のように端末画面へ描画する表示は移さず、WezTerm のネイティブ UI で表せる範囲に留める。

local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()


-- ---
-- Default domain
-- ---
-- 起動時、およびタブとペインの新規作成時に接続する先。
-- WSL のディストリビューションは "WSL:" を前置したドメイン名として WezTerm が列挙する。
-- 名前は wsl -l -v の出力と一致する。
config.default_domain = 'WSL:Ubuntu-24.04'


-- ---
-- Launch menu
-- ---
-- 起動する接続先とプログラムの一覧。タブバーの新規タブボタンの右クリック、
-- および Alt+Shift+w の ShowLauncherArgs で開く。
-- domain を省いた場合は default_domain で起動するため、Windows 側のシェルには local ドメインを明示する。
config.launch_menu = {
    {
        label = 'WSL: Ubuntu-24.04',
        domain = { DomainName = 'WSL:Ubuntu-24.04' },
    },
    {
        label = 'PowerShell',
        args = { 'powershell.exe', '-NoLogo' },
        domain = { DomainName = 'local' },
    },
    {
        label = 'Command Prompt',
        args = { 'cmd.exe' },
        domain = { DomainName = 'local' },
    },
}


-- ---
-- Font
-- ---
-- Windows Terminal のプロファイルと同じフォントとサイズ。
-- font_size と Windows Terminal の font.size はともにポイント単位であり、
-- ピクセル数への変換にはディスプレイの DPI を用いるため、同じ値が同じ大きさになる。
-- 値を変える場合は .chezmoitemplates/windows-terminal-settings.json も合わせること。
config.font = wezterm.font_with_fallback { 'Consolas', 'BIZ UDGothic' }
config.font_size = 10.0

-- Windows Terminal のプロファイルと同じ配色。
config.color_scheme = 'OneHalfDark'


-- ---
-- Window appearance
-- ---
-- 背景を半透明にし、背後をぼかす。
-- Acrylic は背後の内容をぼかす効果である。壁紙の色を映すだけの Mica や Tabbed とは異なり、
-- 不透明度を残したまま用いる。
-- 効果を得るには window_background_opacity が 1.0 未満である必要がある。
config.window_background_opacity = 0.9
config.win32_system_backdrop = 'Acrylic'


-- ---
-- Leader
-- ---
-- tmux の prefix と同じ Ctrl+a。
-- tmux の prefix は次の入力を無期限に待つが、WezTerm は待ち時間の指定を要する。
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }


-- ---
-- Key bindings
-- ---
-- 既定のキー割り当ては残し、tmux から移す分のみを上書きする。
config.keys = {
    -- Leader
    -- 二度押しで Ctrl+a 自体を WSL 側へ送る。tmux の send-prefix に相当する。
    { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
    -- 設定の再読み込み。WezTerm は設定ファイルの変更を自動で検知するため、明示的に行う手段として置く。
    { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },

    -- Launch menu
    -- 接続先を選んでタブを開く。列挙する対象は launch_menu の項目と接続先のドメインに限る。
    -- key_map_preference の既定は Mapped であり、key はキーの位置ではなく入力される文字を指す。
    -- SHIFT を伴うため、指定する文字は大文字である。
    {
        key = 'W',
        mods = 'ALT|SHIFT',
        action = act.ShowLauncherArgs { flags = 'LAUNCH_MENU_ITEMS|DOMAINS' },
    },

    -- Tab
    -- tmux の window に対応する。
    { key = 'w', mods = 'ALT', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'd', mods = 'ALT', action = act.CloseCurrentTab { confirm = true } },
    { key = 'RightArrow', mods = 'SHIFT', action = act.ActivateTabRelative(1) },
    { key = 'LeftArrow', mods = 'SHIFT', action = act.ActivateTabRelative(-1) },

    -- Pane splitting
    { key = '\\', mods = 'ALT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = '-', mods = 'ALT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

    -- Pane deletion
    { key = 'Delete', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } },

    -- Pane zoom
    { key = 'z', mods = 'ALT', action = act.TogglePaneZoomState },

    -- Pane navigation
    -- ActivatePaneDirection は端のペインで折り返さない。tmux 側の pane_at_* による分岐と同じ挙動である。
    { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
    { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },

    -- Pane resize
    { key = ']', mods = 'ALT', action = act.AdjustPaneSize { 'Right', 5 } },
    { key = '[', mods = 'ALT', action = act.AdjustPaneSize { 'Left', 5 } },
    { key = 'PageUp', mods = 'ALT', action = act.AdjustPaneSize { 'Up', 5 } },
    { key = 'PageDown', mods = 'ALT', action = act.AdjustPaneSize { 'Down', 5 } },

    -- Copy mode
    { key = 'a', mods = 'ALT', action = act.ActivateCopyMode },
}


-- ---
-- Copy mode
-- ---
-- WezTerm の copy_mode キーテーブルは vi のキー操作を既定に持つ。tmux の mode-keys vi に対応する。
-- y はコピーして抜ける動作を既定に持つが、Enter は次行の行頭への移動である。
-- tmux は双方をコピーへ割り当てていたため、既定のキーテーブルを取り出して Enter のみを差し替える。
-- コピー先は Windows のクリップボードであり、tmux が WSL 上で行っていた clip.exe への受け渡しは要さない。
-- wezterm.gui は multiplexer サーバ側では nil であるため、存在を確かめてから参照する。
local copy_mode = nil
if wezterm.gui then
    copy_mode = wezterm.gui.default_key_tables().copy_mode
    table.insert(copy_mode, {
        key = 'Enter',
        mods = 'NONE',
        action = act.Multiple {
            { CopyTo = 'ClipboardAndPrimarySelection' },
            { CopyMode = 'ScrollToBottom' },
            { CopyMode = 'Close' },
        },
    })
end

config.key_tables = {
    copy_mode = copy_mode,
}


-- ---
-- Tab bar
-- ---
-- tmux の status line に対応する。位置は status-position top に合わせて上端とし、
-- タブが 1 つのときも隠さないことで、tmux の常時表示と同じ見えかたにする。
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false


-- ---
-- Tab title
-- ---
-- tmux の automatic-rename-format "#{b:pane_current_path}" に対応し、カレントディレクトリ名を表示する。

-- パスの末尾の要素を返す。区切りは / と \ の双方を受け付ける。
-- path: 末尾に区切りを含んでもよいパス
-- 戻り値: 末尾の要素。末尾の区切りを除いた結果が空になる場合は nil
local function basename(path)
    return path:gsub('[/\\]+$', ''):match('[^/\\]+$')
end

-- タブに表示する文字列を返す。
-- カレントディレクトリはシェルが OSC 7 で通知した値を用いる。
-- WSL のペインでは Windows 側からプロセスのカレントディレクトリを辿れず、通知が無ければ得られないため、
-- その場合はペインのタイトルへ退避する。
-- pane: PaneInformation
-- 戻り値: タブに表示する文字列
local function tab_title(pane)
    local cwd = pane.current_working_dir
    if cwd ~= nil then
        -- 20240127 以降は Url オブジェクト、それ以前は文字列を返す。
        local path = type(cwd) == 'string' and cwd or cwd.file_path
        local name = basename(path)
        if name ~= nil then
            return name
        end
    end
    return pane.title
end

wezterm.on('format-tab-title', function(tab, tabs, panes, conf, hover, max_width)
    -- 左右の空白 2 文字分を差し引いた幅へ収める。
    return ' ' .. wezterm.truncate_right(tab_title(tab.active_pane), max_width - 2) .. ' '
end)


-- ---
-- Leader indicator
-- ---
-- tmux の status-format に置いた client_prefix の表示に対応し、leader を押している間だけ表示する。
wezterm.on('update-right-status', function(window, pane)
    local text = ''
    if window:leader_is_active() then
        text = ' LEADER '
    end

    window:set_right_status(wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Yellow' } },
        { Text = text },
    })
end)


-- ---
-- Pane appearance
-- ---
-- 非アクティブなペインを減光する。tmux の window-style と window-active-style による色分けに対応する。
config.inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.7,
}


return config
