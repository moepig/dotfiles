-- Windows 上の WezTerm の設定。
-- WSL 上の tmux で用いていた操作と表示を、WezTerm のタブ、ペイン、タブバーへ対応付ける。
-- 端末画面への描画は行わず、表示はすべてタブバーの領域で行う。

local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()


-- ---
-- Palette
-- ---
-- タブバーとペインの区切り線の描画に用いる色。色番号ではなく色の直接の指定を要するため、
-- color_scheme とは別に持つ。
-- 背景色は bar_bg、tab_bg と list_bg、hover_bg、active_bg の順に明るく、いずれも color_scheme が
-- 定める端末画面の背景色より明るい。タブバーを端末画面より明るい面とすることで、タブバーの
-- 領域と端末画面との境目を明度の差で示す。
-- bar_bg は、タブバーの地である。タブの間、およびタブ、ペイン一覧、接続先の一覧の間に覗く。
-- tab_bg はタブが、list_bg はペイン一覧が占める領域へ敷く背景色であり、bar_bg より明るいことで
-- 領域の範囲を示す。
-- active_bg は、ペイン一覧のアクティブなペインへ敷く背景色である。
-- on_fill は、接続先の色で塗った背景の上に置く文字色である。
-- dim は、アクティブでない項目の文字と区切りに用いる文字色であり、tab_bg と list_bg の上で
-- fg より弱く読める明度を持つ。
-- split は、ペインの区切り線の色である。
local palette = {
    bar_bg = '#343a46',
    tab_bg = '#434a58',
    list_bg = '#434a58',
    hover_bg = '#525b6c',
    active_bg = '#5a6376',
    fg = '#dcdfe4',
    on_fill = '#21252b',
    dim = '#98a0b0',
    accent = '#c678dd',
    split = '#454b57',
}


-- ---
-- Exec domains
-- ---
-- PowerShell を起動するドメイン。exec domain は、そのドメインで起動する SpawnCommand を受け取り、
-- 置き換えたものを返す関数を伴うドメインである。
-- local ドメインと分けて持つのは、ペインの種別の判別とセッションの復元が、いずれもペインの属する
-- ドメイン名から起動するプログラムを定めるためである。local ドメインの既定は cmd.exe であり、
-- PowerShell を local ドメインへ置くと Command Prompt のペインと区別できない。
config.exec_domains = {
    wezterm.exec_domain('PowerShell', function(cmd)
        cmd.args = { 'powershell.exe', '-NoLogo' }
        return cmd
    end),
}


-- ---
-- Spawn targets
-- ---
-- 起動できる接続先とプログラムの一覧。launch menu、タブバー右端の一覧、Alt+1 から Alt+3 の
-- キー割り当て、タブの色が、いずれもこの一覧を参照する。
-- 接続先はドメインで一意に定まる。ドメイン名がペインの種別を表し、起動するプログラムはドメインが定める。
-- domain を省いた場合は default_domain で起動するため、Windows 側のシェルにもドメインを明示する。
-- color と dim_color は、いずれも種別を表す同じ色相の色である。color をタブと、ペイン一覧の
-- アクティブなペインへ、彩度を落とした dim_color をペイン一覧のそれ以外のペインへ用いる。
-- dim_color の明度は list_bg より高く、list_bg の上で読める。
local spawn_targets = {
    {
        label = 'WSL: Ubuntu-24.04',
        short = 'WSL',
        color = '#98c379',
        dim_color = '#76936c',
        domain = { DomainName = 'WSL:Ubuntu-24.04' },
    },
    {
        label = 'PowerShell',
        short = 'PS',
        color = '#61afef',
        dim_color = '#5587b3',
        domain = { DomainName = 'PowerShell' },
    },
    {
        label = 'Command Prompt',
        short = 'CMD',
        color = '#e5c07b',
        dim_color = '#a4916d',
        domain = { DomainName = 'local' },
    },
}

-- spawn_targets のどの要素にも対応しないペインへ用いる種別。
-- 種別を表す色相を持たないため、color と dim_color の双方を dim とする。
local unknown_target = {
    short = '-',
    color = palette.dim,
    dim_color = palette.dim,
}

-- spawn_targets の要素から SpawnCommand を作る。
-- 起動するプログラムを指定せず、ドメインの既定に委ねる。
-- target: spawn_targets の要素
-- 戻り値: SpawnCommand
local function spawn_command(target)
    return {
        label = target.label,
        domain = target.domain,
    }
end


-- ---
-- Default domain
-- ---
-- 起動時、およびタブとペインの新規作成時に接続する先。
-- WSL のディストリビューションは "WSL:" を前置したドメイン名として WezTerm が列挙する。
-- 名前は wsl -l -v の出力と一致する。
config.default_domain = spawn_targets[1].domain.DomainName


-- ---
-- Default program
-- ---
-- local ドメインで、起動するプログラムの指定が無い場合に起動するもの。
-- ペインの分割とセッションの復元は、起動するプログラムをドメインの既定に委ねるため、
-- WezTerm の定める既定に依らず明示する。
config.default_prog = { 'cmd.exe' }


-- ---
-- Environment variables
-- ---
-- local ドメインと exec domain で起動するプログラムへ渡す環境変数。WSL のドメインへは渡らない。
-- prompt は cmd.exe がプロンプトの書式として読む環境変数であり、他のシェルは読まない。
-- 書式の先頭に OSC 7 を置き、カレントディレクトリを URL として WezTerm へ通知する。
-- $E が ESC、$P がカレントディレクトリ、$G が > を表す。
-- https://wezterm.org/shell-integration.html
-- 「cmd.exe doesn't allow a lot of flexibility in configuring the prompt, but fortunately it does
-- allow for emitting escape sequences. You can use the set_environment_variables configuration to
-- pre-configure the prompt environment in your .wezterm.lua」
config.set_environment_variables = {
    prompt = '$E]7;file://localhost/$P$E\\$P$G ',
}


-- ---
-- Launch menu
-- ---
-- 起動する接続先とプログラムの一覧。タブバーの新規タブボタンの右クリック、
-- および Alt+Shift+w の ShowLauncherArgs で開く。
config.launch_menu = {}
for _, target in ipairs(spawn_targets) do
    table.insert(config.launch_menu, spawn_command(target))
end


-- ---
-- Font
-- ---
-- Consolas に含まれない字形は BIZ UDGothic へ退避する。
-- font_size はポイント単位であり、ピクセル数への変換にはディスプレイの DPI を用いる。
config.font = wezterm.font_with_fallback { 'Consolas', 'BIZ UDGothic' }
config.font_size = 10.0

config.color_scheme = 'OneHalfDark'


-- ---
-- Window appearance
-- ---
-- 背景は不透明とする。1.0 未満の不透明度と、それを前提とする win32_system_backdrop の Acrylic は、
-- 背後のウィンドウとデスクトップの色を映して画面全体の明度を上げ、
-- color_scheme が定める色より明るく見せるためである。
config.window_background_opacity = 1.0


-- ---
-- Window size
-- ---
-- 起動時のウィンドウの大きさ。WezTerm の既定である 80 桁 24 行の 2.5 倍とする。
config.initial_cols = 200
config.initial_rows = 60


-- ---
-- Working directory
-- ---
-- 起動時、および新規のタブとペインのカレントディレクトリ。
-- WezTerm は分割元のペインのカレントディレクトリを引き継ぎ、それが不明な場合にドメインの
-- default_cwd を、default_cwd も無い場合に Windows のホームディレクトリを用いる。
-- 分割元のカレントディレクトリは、シェルが OSC 7 で通知した値、または Windows 側のペインの
-- プロセスから得る。OSC 7 の通知は、WSL のペインではシェルの初期設定が、Command Prompt の
-- ペインでは set_environment_variables の prompt が行う。
-- 起動時は引き継ぐ先が無いため、WSL のドメインの default_cwd へ WSL 上のホームディレクトリを
-- 置く。置かない場合、WSL のペインは Windows のホームディレクトリで開き、WSL からは
-- /mnt/c/Users/<ユーザー名> として見える。~ は、WezTerm が --cd へ渡す先の wsl.exe が
-- WSL 上のホームディレクトリとして解釈する。
-- 引き継ぎは default_cwd より優先されるため、分割と新規タブの引き継ぎは変わらない。
-- ドメインを問わず用いられる config.default_cwd は置かない。Windows 側のペインを WSL 上の
-- パスで起動することになるためである。
-- 一覧は、wezterm.default_wsl_domains() が wsl -l -v から作る既定へ default_cwd のみを加える。
-- config.wsl_domains へ直接書いた場合、書いたドメインのみが列挙の対象となるためである。
local wsl_domains = wezterm.default_wsl_domains()
for _, domain in ipairs(wsl_domains) do
    domain.default_cwd = '~'
end
config.wsl_domains = wsl_domains


-- ---
-- Leader
-- ---
-- tmux の prefix と同じ Ctrl+a。
-- tmux の prefix は次の入力を無期限に待つが、WezTerm は待ち時間の指定を要する。
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }


-- ---
-- Key help
-- ---
-- Alt+h で開くキー割り当ての一覧。tmux の list-keys に対応する。
-- 内容は config.keys とは独立に持つため、キー割り当てを変えた場合は双方を更新すること。
-- section を持つ要素は見出しであり、key と desc を持つ要素は 1 件のキー割り当てである。
local key_help = {
    { section = 'Help' },
    { key = 'Alt+h', desc = 'この一覧' },
    { section = 'Leader' },
    { key = 'Ctrl+a', desc = 'leader' },
    { key = 'Ctrl+a Ctrl+a', desc = 'Ctrl+a を接続先へ送る' },
    { key = 'Ctrl+a r', desc = '設定の再読み込み' },
    { key = 'Ctrl+a s', desc = 'セッションの保存' },
    { section = 'Tab' },
    { key = 'Alt+w', desc = 'タブの新規作成' },
    { key = 'Alt+1 Alt+2 Alt+3', desc = '接続先を指定したタブの新規作成' },
    { key = 'Alt+Shift+w', desc = 'launch menu を開く' },
    { key = 'Alt+d', desc = 'タブを閉じる。確認を求める' },
    { key = 'Shift+Left Shift+Right', desc = '前後のタブへ移動' },
    { section = 'Pane' },
    { key = 'Alt+\\', desc = 'ペインを左右へ分割' },
    { key = 'Alt+-', desc = 'ペインを上下へ分割' },
    { key = 'Alt+方向キー', desc = '隣のペインへ移動。端では折り返さない' },
    { key = 'Alt+z', desc = 'ペインのズームの切り替え' },
    { key = 'Alt+[ Alt+]', desc = 'ペインの幅を 5 桁ずつ増減' },
    { key = 'Alt+PageUp Alt+PageDown', desc = 'ペインの高さを 5 行ずつ増減' },
    { key = 'Alt+Delete', desc = 'ペインを閉じる。確認は求めない' },
    { section = 'Copy mode' },
    { key = 'Alt+a', desc = 'コピーモードへ入る' },
    { key = 'y Enter', desc = 'コピーして抜ける。コピーモード中のみ' },
}

-- キーの欄に与える桁数。key_help のどの key よりも広い。
local key_help_width = 26

-- key_help から InputSelector の choices を組み立てる。
-- 戻り値: choices。並びは key_help と同じである
local function key_help_choices()
    local choices = {}
    for _, entry in ipairs(key_help) do
        local label
        if entry.section ~= nil then
            label = wezterm.format {
                { Foreground = { Color = palette.accent } },
                { Attribute = { Intensity = 'Bold' } },
                { Text = entry.section },
            }
        else
            label = wezterm.format {
                { Foreground = { Color = palette.fg } },
                { Text = '  ' .. wezterm.pad_right(entry.key, key_help_width) },
                { Foreground = { Color = palette.dim } },
                { Text = entry.desc },
            }
        end
        table.insert(choices, { label = label })
    end
    return choices
end


-- ---
-- Path
-- ---

-- パスの末尾の要素を返す。区切りは / と \ の双方を受け付ける。
-- path: 末尾に区切りを含んでもよいパス
-- 戻り値: 末尾の要素。要素が 1 つも無い場合は nil
local function base_name(path)
    local name = nil
    for part in path:gmatch('[^/\\]+') do
        name = part
    end
    return name
end

-- ---
-- Pane state
-- ---
-- ペインの状態は、format-tab-title へ渡る PaneInformation と、panes_with_info が返す Pane の
-- 双方から取り出す。両者は同じ値を別の名前で持つため、以下の表へ揃えてから表示に用いる。
--   cwd: カレントディレクトリのパス。得られない場合は nil
--   title: ペインのタイトル
--   domain: 接続先のドメイン名

-- カレントディレクトリを表す値をパスへ揃える。
-- cwd: Url オブジェクト、文字列、または nil
-- 戻り値: パス。cwd が nil の場合は nil
local function cwd_path(cwd)
    if cwd == nil then
        return nil
    end
    -- 20240127 以降は Url オブジェクト、それ以前は文字列を返す。
    return type(cwd) == 'string' and cwd or cwd.file_path
end

-- PaneInformation から表示に用いる値を取り出す。
-- pane: PaneInformation
-- 戻り値: ペインの状態
local function state_of_info(pane)
    return {
        cwd = cwd_path(pane.current_working_dir),
        title = pane.title,
        domain = pane.domain_name,
    }
end

-- Pane から表示に用いる値を取り出す。
-- pane: Pane
-- 戻り値: ペインの状態
local function state_of_pane(pane)
    return {
        cwd = cwd_path(pane:get_current_working_dir()),
        title = pane:get_title(),
        domain = pane:get_domain_name(),
    }
end

-- ペインのカレントディレクトリ名を表す文字列を返す。
-- state: ペインの状態
-- 戻り値: 表示する文字列。カレントディレクトリが得られない場合はペインのタイトル。
--         いずれも得られない場合は "-"
local function cwd_label(state)
    if state.cwd ~= nil then
        local label = base_name(state.cwd)
        if label ~= nil then
            return label
        end
    end
    if state.title ~= nil and state.title ~= '' then
        return state.title
    end
    return '-'
end


-- ---
-- Pane kind
-- ---

-- ドメイン名から spawn_targets の要素を引く表。
local targets_by_domain = {}
for _, target in ipairs(spawn_targets) do
    targets_by_domain[target.domain.DomainName] = target
end

-- ペインの接続先に対応する spawn_targets の要素を返す。
-- state: ペインの状態
-- 戻り値: spawn_targets の要素。ドメイン名がいずれの接続先とも一致しない場合は unknown_target
local function target_of(state)
    return targets_by_domain[state.domain] or unknown_target
end


-- ---
-- Key bindings
-- ---
-- 既定のキー割り当ては残し、tmux から移す分と接続先を指定する分のみを上書きする。
config.keys = {
    -- Leader
    -- 二度押しで Ctrl+a 自体を WSL 側へ送る。tmux の send-prefix に相当する。
    { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
    -- 設定の再読み込み。WezTerm は設定ファイルの変更を自動で検知するため、明示的に行う手段として置く。
    { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },

    -- Key help
    -- キー割り当ての一覧。InputSelector は選択のための UI であるが、選択して閉じる以外の動作を
    -- 与えないことで一覧の表示に用いる。alphabet を空とし、項目へ選択用の文字を付けない。
    {
        key = 'h',
        mods = 'ALT',
        action = act.InputSelector {
            title = 'キー割り当ての一覧',
            description = 'Esc で閉じる',
            choices = key_help_choices(),
            alphabet = '',
            fuzzy = false,
            action = wezterm.action_callback(function() end),
        },
    },

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
    -- 分割元のドメインとカレントディレクトリを引き継ぐ。起動するプログラムはドメインの既定である。
    {
        key = '\\',
        mods = 'ALT',
        action = act.SplitPane { direction = 'Right', command = { domain = 'CurrentPaneDomain' } },
    },
    {
        key = '-',
        mods = 'ALT',
        action = act.SplitPane { direction = 'Down', command = { domain = 'CurrentPaneDomain' } },
    },

    -- Pane deletion
    -- タブとは異なり確認を求めない。閉じる対象がタブ全体ではなくペイン 1 つに限られるためである。
    { key = 'Delete', mods = 'ALT', action = act.CloseCurrentPane { confirm = false } },

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

-- 接続先を指定したタブの新規作成。Alt+1 から Alt+3 が spawn_targets の並び順に対応する。
for i, target in ipairs(spawn_targets) do
    table.insert(config.keys, {
        key = tostring(i),
        mods = 'ALT',
        action = act.SpawnCommandInNewTab(spawn_command(target)),
    })
end


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
            { CopyMode = 'MoveToScrollbackBottom' },
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
-- 右端のペイン一覧と接続先の一覧を等幅で並べるため、fancy tab bar ではなく retro tab bar を用いる。
-- retro tab bar は端末の 1 行として描かれるため、縦幅は端末のフォントの大きさが定める。
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 28

-- タブの背景色と文字色は format-tab-title が返す書式が定めるため、active_tab と inactive_tab は
-- 書式を組み立てられない場合の値として置く。
config.colors = {
    tab_bar = {
        background = palette.bar_bg,
        active_tab = { bg_color = palette.tab_bg, fg_color = palette.fg, intensity = 'Bold' },
        inactive_tab = { bg_color = palette.tab_bg, fg_color = palette.fg },
        inactive_tab_hover = { bg_color = palette.hover_bg, fg_color = palette.fg },
        new_tab = { bg_color = palette.bar_bg, fg_color = palette.dim },
        new_tab_hover = { bg_color = palette.hover_bg, fg_color = palette.fg },
    },
}


-- ---
-- Tab title
-- ---
-- カレントディレクトリ名のみを置き、接続先の種別はその色で表す。アクティブなタブは接続先の色を
-- 背景へ、他のタブは文字へ置き、両者を塗り分けで隔てる。明度を落としたタブを作らないことで、
-- どのタブのカレントディレクトリ名も同じ読みやすさとする。アクティブなタブとの差は塗り分けが
-- 付けるため、括弧や記号は添えない。
-- カレントディレクトリ名は tmux の automatic-rename-format "#{b:pane_current_path}" に対応する。
wezterm.on('format-tab-title', function(tab, tabs, panes, conf, hover, max_width)
    local state = state_of_info(tab.active_pane)
    local target = target_of(state)
    -- タブの左の空白 1 文字分と、カレントディレクトリ名の左右の空白 1 文字分を差し引いた幅へ収める。
    local title = wezterm.truncate_right(cwd_label(state), math.max(max_width - 3, 1))

    -- アクティブなタブは接続先の色を背景色とし、文字色を暗い側とする。アクティブでないタブは
    -- タブの領域の色を背景色とし、接続先の色を文字色とする。マウスが乗っているタブは背景色のみを変える。
    local bg = palette.tab_bg
    local fg = target.color
    if tab.is_active then
        bg = target.color
        fg = palette.on_fill
    elseif hover then
        bg = palette.hover_bg
    end

    return {
        -- タブの左へタブバーの地を 1 文字分覗かせ、隣のタブおよびタブバーの左端と隔てる。
        { Background = { Color = palette.bar_bg } },
        { Text = ' ' },
        { Background = { Color = bg } },
        { Attribute = { Intensity = tab.is_active and 'Bold' or 'Normal' } },
        { Foreground = { Color = fg } },
        { Text = ' ' .. title .. ' ' },
    }
end)


-- ---
-- Git branch
-- ---
-- ブランチ名は、カレントディレクトリから遡って見つけた .git の HEAD から読む。WezTerm は
-- Git の状態を持たず、外部のコマンドを起動せずに得られるのがファイルの内容に限るためである。

-- ブランチ名を調べた結果を、カレントディレクトリのパスごとに保つ表。
-- 値は、ブランチ名または false を持つ label と、調べた時刻を秒で持つ at の組である。
-- 生存期間は branch_cache_ttl であり、設定の再読み込みで失われる。
local branch_cache = {}

-- branch_cache の値をファイルの再読み込みなしに用いる秒数。
local branch_cache_ttl = 3

-- ブランチ名に与える桁数の上限。
local branch_max_width = 24

-- ファイルの内容を返す。
-- path: ファイルのパス
-- 戻り値: 内容。開けない場合は nil
local function read_file(path)
    local file = io.open(path, 'rb')
    if file == nil then
        return nil
    end
    local content = file:read('*a')
    file:close()
    return content
end

-- ペインのカレントディレクトリを、Windows から開けるパスへ変換する。
-- state: ペインの状態
-- 戻り値: パスと、上位のディレクトリを辿る際の下限となるパス。ドライブのパスではドライブ文字までを、
--         WSL のパスでは UNC の共有名までを下限とする。変換できない場合は nil
local function local_dir(state)
    if state.cwd == nil then
        return nil
    end

    -- Url が返すパスは、ドライブ文字の前に "/" を伴う場合がある。
    local path = state.cwd:gsub('^/(%a:)', '%1'):gsub('/', '\\')
    local drive = path:match('^%a:')
    if drive ~= nil then
        return path, drive
    end

    -- WSL のドメインのペインのパスは WSL 上の位置であり、Windows からは UNC パスで開ける。
    local distro = state.domain ~= nil and state.domain:match('^WSL:(.+)$') or nil
    if distro ~= nil then
        local root = '\\\\wsl.localhost\\' .. distro
        return root .. path, root
    end

    return nil
end

-- ディレクトリの直下の .git が持つ HEAD の内容を返す。
-- dir: ディレクトリのパス
-- root: dir の根のパス
-- 戻り値: HEAD の内容。.git が無い場合と、.git が HEAD を持たない場合は nil
local function head_of(dir, root)
    local git = dir .. '\\.git'

    local content = read_file(git .. '\\HEAD')
    if content ~= nil then
        return content
    end

    -- worktree と submodule の .git はファイルであり、Git のディレクトリの位置を持つ。
    local pointer = read_file(git)
    if pointer == nil then
        return nil
    end
    local gitdir = pointer:match('gitdir:%s*(.-)%s*$')
    if gitdir == nil then
        return nil
    end

    gitdir = gitdir:gsub('/', '\\')
    if gitdir:match('^\\[^\\]') then
        -- WSL のペインの .git が持つ絶対パスは、WSL 上の位置である。
        gitdir = root .. gitdir
    elseif gitdir:match('^%a:') == nil and gitdir:match('^\\\\') == nil then
        gitdir = dir .. '\\' .. gitdir
    end
    return read_file(gitdir .. '\\HEAD')
end

-- HEAD の内容が指すブランチ名を返す。
-- content: HEAD の内容
-- 戻り値: ブランチ名。HEAD がコミットを直接指す場合はコミットハッシュの先頭 7 桁。
--         いずれとしても読めない場合は nil
local function head_label(content)
    local ref = content:match('ref:%s*refs/heads/(%S+)')
    if ref ~= nil then
        return ref
    end
    local sha = content:match('^(%x+)')
    if sha ~= nil then
        return sha:sub(1, 7)
    end
    return nil
end

-- ペインのカレントディレクトリが属する Git リポジトリのブランチ名を返す。
-- カレントディレクトリから根まで遡り、最初に見つかった .git を用いる。
-- state: ペインの状態
-- 戻り値: ブランチ名。リポジトリの外の場合と、カレントディレクトリを Windows から開けない場合は nil
local function branch_of(state)
    local dir, root = local_dir(state)
    if dir == nil then
        return nil
    end

    local now = os.time()
    local cached = branch_cache[dir]
    if cached ~= nil and now - cached.at < branch_cache_ttl then
        return cached.label or nil
    end

    local label = nil
    local at = dir
    while at ~= nil and #at > #root do
        local head = head_of(at, root)
        if head ~= nil then
            label = head_label(head)
            break
        end
        at = at:match('^(.*)\\[^\\]*$')
    end

    branch_cache[dir] = { label = label or false, at = now }
    return label
end


-- ---
-- Status
-- ---
-- tmux の status-format に置いていた表示に対応する。右端へ、ブランチ名、ペイン一覧、
-- 接続先の一覧をこの順で並べる。
-- 左端には何も置かず、タブを左端から並べる。
-- キー割り当ての一覧は常時は置かない。タブバーが 1 行しか無く、ペイン一覧とタブが同じ行を
-- 分け合うためである。一覧の表示は Alt+h が担う。

-- leader を押している間に表示する、leader に続くキーの一覧。
local leader_hint = 'LEADER  Ctrl+a 送出 │ r 設定の再読み込み'

-- 右端の左端に表示するブランチ名を組み立てる。
-- 対象はアクティブなペインである。文字色はどの接続先の色とも異なる accent とし、
-- ペイン一覧のカレントディレクトリと区別する。
-- tmux の pane-border-format に置いていた表示に対応する。
-- pane: Pane
-- 戻り値: wezterm.format による書式付きの文字列。末尾に、続く表示との間隔を含む。
--         ブランチ名が得られない場合は空文字列
local function branch_status(pane)
    local branch = branch_of(state_of_pane(pane))
    if branch == nil then
        return ''
    end

    return wezterm.format {
        { Background = { Color = palette.bar_bg } },
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { Color = palette.accent } },
        { Text = wezterm.truncate_right(branch, branch_max_width) },
        { Attribute = { Intensity = 'Normal' } },
        { Text = '   ' },
    }
end

-- 右端に表示するペイン一覧を組み立てる。
-- 対象はアクティブなタブのペインである。ペインごとに、接続先の短縮名と
-- カレントディレクトリ名を並べ、アクティブなペインを明るい背景色、太字、明るい文字色で強調し、
-- ズームしているペインには Z を付ける。
-- 短縮名の文字色は接続先の種別を表し、タブおよび接続先の一覧と同じ色である。
-- アクティブでないペインは、短縮名にもカレントディレクトリ名にも彩度を落とした色を用いる。
-- WezTerm はペインごとのヘッダを持たないため、ペインの情報はこの一覧が担う。
-- window: Window
-- 戻り値: wezterm.format による書式付きの文字列。末尾に、続く表示との間隔を含む
local function pane_list(window)
    -- 一覧の占める領域は背景色で示す。領域には、ペインの間の区切りと、ペインごとの左右の
    -- 空白 1 文字分を含む。空白を一覧の両端ではなくペインごとに持たせることで、アクティブな
    -- ペインへ敷く背景色が左右の空白まで届き、かつ一覧の桁数がどのペインをアクティブとするかに
    -- 依らない。
    local items = {}
    local first = true

    for _, info in ipairs(window:active_tab():panes_with_info()) do
        if not first then
            table.insert(items, { Background = { Color = palette.list_bg } })
            table.insert(items, { Foreground = { Color = palette.dim } })
            table.insert(items, { Attribute = { Intensity = 'Normal' } })
            table.insert(items, { Text = '│' })
        end
        first = false

        local state = state_of_pane(info.pane)
        local target = target_of(state)
        local label = cwd_label(state)
        if info.is_zoomed then
            label = label .. ' Z'
        end

        table.insert(items, { Background = { Color = info.is_active and palette.active_bg or palette.list_bg } })
        table.insert(items, { Attribute = { Intensity = info.is_active and 'Bold' or 'Normal' } })
        table.insert(items, { Foreground = { Color = info.is_active and target.color or target.dim_color } })
        table.insert(items, { Text = ' ' .. target.short .. ' ' })
        table.insert(items, { Foreground = { Color = info.is_active and palette.fg or palette.dim } })
        table.insert(items, { Text = label .. ' ' })
    end

    -- 一覧の領域を閉じ、続く表示との間に間隔を置く。
    table.insert(items, { Background = { Color = palette.bar_bg } })
    table.insert(items, { Attribute = { Intensity = 'Normal' } })
    table.insert(items, { Text = '   ' })

    return wezterm.format(items)
end

-- 右端に表示する接続先の一覧を組み立てる。
-- 一覧には、対応する Alt+数字 の数字を添える。文字色は接続先の色であり、
-- タブの色から接続先を読み取るための対応表を兼ねる。
-- leader を押している間は、leader に続くキーの一覧を接続先の一覧の左へ添える。
-- window: Window
-- 戻り値: wezterm.format による書式付きの文字列
local function status_hints(window)
    -- 先行する表示から背景色を引き継がないよう、タブバーの背景色を明示する。
    local items = { { Background = { Color = palette.bar_bg } } }

    if window:leader_is_active() then
        table.insert(items, { Foreground = { AnsiColor = 'Yellow' } })
        table.insert(items, { Attribute = { Intensity = 'Bold' } })
        table.insert(items, { Text = ' ' .. leader_hint })
    end

    table.insert(items, { Attribute = { Intensity = 'Bold' } })
    for i, target in ipairs(spawn_targets) do
        table.insert(items, { Foreground = { Color = palette.dim } })
        table.insert(items, { Text = ' │ ' })
        table.insert(items, { Foreground = { Color = target.color } })
        table.insert(items, { Text = string.format('%d %s', i, target.short) })
    end
    table.insert(items, { Text = ' ' })

    return wezterm.format(items)
end

wezterm.on('update-status', function(window, pane)
    window:set_left_status('')
    window:set_right_status(branch_status(pane) .. pane_list(window) .. status_hints(window))
end)


-- ---
-- Pane appearance
-- ---
-- 非アクティブなペインの文字と背景を暗くし、アクティブなペインを最も明るくする。
-- tmux の window-style と window-active-style による色分けに対応する。
-- brightness と saturation は倍率であり、1.0 未満の値は元の色より弱い色を与える。
config.inactive_pane_hsb = {
    saturation = 0.7,
    brightness = 0.4,
}

-- ペインの区切り線の色。区切り線は、分割したペインの間へ WezTerm が置く 1 桁または 1 行の境界である。
config.colors.split = palette.split


-- ---
-- Session
-- ---
-- ウィンドウ、タブ、ペインの構成を保存し、次の起動で復元する。
-- tmux-resurrect と tmux-continuum による、セッションの保存と復元に対応する。
-- WezTerm 自体は構成の保存と復元を持たないため、resurrect.wezterm プラグインを用いる。
-- プラグインの取得は wezterm.plugin.require が行う。初回は GitHub から複製し、以降は
-- %APPDATA%\wezterm\plugins の複製を読み込む。
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'

-- 状態の保存先。末尾の区切りを含むパスを渡す。
-- 保存先の既定はプラグインの複製の中であり、プラグインの取得し直しで失われるため、設定と同じ位置へ移す。
-- ディレクトリは存在していることを要する。プラグインによる作成は Windows では成功しない。
local state_dir = wezterm.home_dir .. '\\.config\\wezterm\\state\\'
resurrect.state_manager.change_state_save_dir(state_dir)

-- ペイン 1 つにつき保存するスクロールバックの行数の上限。
-- 保存の対象は local ドメインのペインに限られる。WSL のペインの内容は保存しない。
resurrect.state_manager.set_max_nlines(1000)

-- 状態を保存する間隔。WezTerm は終了時のイベントを持たないため、復元できるのは最後の保存の時点である。
local save_interval_seconds = 60

-- 定期的な保存の開始。設定を評価するたびに開始する。
-- 繰り返しは wezterm.time.call_after が担い、その予定は設定を評価し直した時点で失われる。
-- WezTerm は起動時に設定を複数回評価し、以降も再読み込みのたびに評価し直すため、
-- 開始済みであることを wezterm.GLOBAL へ記録して 2 回目以降の評価で開始を省くと、
-- 繰り返しを持たない評価だけが残り、保存が一度も行われない。
-- 評価のたびに開始しても繰り返しは重ならない。前の評価の予定が残らないためである。
resurrect.state_manager.periodic_save {
    interval_seconds = save_interval_seconds,
    save_workspaces = true,
}

-- 手動での保存。定期的な保存の間隔を待たずに、押した時点の構成を保存する。
-- 保存する内容と保存先は定期的な保存と同じであり、次の起動はこの保存を復元する。
-- tmux-resurrect の prefix + Ctrl-s に対応する。
-- 割り当てを Key bindings の節ではなくここへ置くのは、動作の実体である resurrect を
-- この節で読み込むためである。一覧は key_help が持つため、双方を更新すること。
table.insert(config.keys, {
    key = 's',
    mods = 'LEADER',
    action = wezterm.action_callback(function()
        resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
        resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), 'workspace')
    end),
})

-- 復元の対象とする workspace の記録。起動時の復元はこの記録を読む。
wezterm.on('resurrect.state_manager.periodic_save.finished', function()
    resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), 'workspace')
end)

-- 起動時の復元。記録が無い場合は復元を行わず、WezTerm が既定のウィンドウを開く。
wezterm.on('gui-startup', resurrect.state_manager.resurrect_on_gui_startup)

-- 保存と復元の失敗の記録。記録は Ctrl+Shift+L のデバッグオーバーレイが表示する。
wezterm.on('resurrect.error', function(err)
    wezterm.log_error('resurrect: ' .. tostring(err))
end)


return config
