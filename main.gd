extends Node2D

const W := 480
const H := 854
var player := Vector2(230, 390)
var facing := Vector2(0, 1)
var mode := "world"
var message := "歡迎來到星野草原！探索四周，尋找你的第一隻夥伴。"
var steps := 0
var coins := 20
var potions := 2
var team := [{"name":"焰尾狐","hp":24,"max_hp":24,"power":7,"level":1}]
var enemy_name := "草芽獸"
var enemy_hp := 18
var enemy_max_hp := 18
var enemy_power := 4
var enemy_turn := false
var caught := 0
var saved_note := "尚未保存"
var buttons := {}

func _ready():
    _build_ui()
    queue_redraw()

func _build_ui():
    var layer = CanvasLayer.new()
    add_child(layer)
    var panel = PanelContainer.new()
    panel.position = Vector2(14, 675)
    panel.size = Vector2(452, 164)
    layer.add_child(panel)
    var outer = VBoxContainer.new()
    panel.add_child(outer)
    var row1 = HBoxContainer.new()
    outer.add_child(row1)
    _add_button(row1, "↑", "up")
    _add_button(row1, "互動", "interact")
    _add_button(row1, "背包", "bag")
    var row2 = HBoxContainer.new()
    outer.add_child(row2)
    _add_button(row2, "←", "left")
    _add_button(row2, "↓", "down")
    _add_button(row2, "→", "right")
    var row3 = HBoxContainer.new()
    outer.add_child(row3)
    _add_button(row3, "攻擊", "attack")
    _add_button(row3, "收服", "catch")
    _add_button(row3, "喝藥水", "potion")
    _add_button(row3, "保存", "save")

func _add_button(parent: HBoxContainer, label_text: String, action: String):
    var b = Button.new()
    b.text = label_text
    b.custom_minimum_size = Vector2(82, 38)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.pressed.connect(_on_action.bind(action))
    parent.add_child(b)
    buttons[action] = b

func _on_action(action: String):
    if mode == "world":
        match action:
            "up": _move(Vector2(0, -1))
            "down": _move(Vector2(0, 1))
            "left": _move(Vector2(-1, 0))
            "right": _move(Vector2(1, 0))
            "interact": _interact()
            "bag": _show_bag()
            "save": _save_game()
            "attack", "catch", "potion": message = "先在草叢探索，遇到怪獸後才能使用戰鬥指令。"
    elif mode == "battle":
        match action:
            "attack": _attack()
            "catch": _catch()
            "potion": _use_potion()
            "save": _save_game()
            "interact": _run_away()
            "bag": _show_bag()
            _: pass
    elif mode == "bag":
        if action == "bag" or action == "interact":
            mode = "world"
            message = "你收好背包，繼續探索吧。"
        elif action == "save":
            _save_game()
    queue_redraw()

func _move(dir: Vector2):
    facing = dir
    player += dir * 22
    player.x = clamp(player.x, 35, 445)
    player.y = clamp(player.y, 130, 610)
    steps += 1
    if steps % 5 == 0:
        _encounter()
    else:
        message = ["草葉隨風搖動……","遠處傳來奇怪的叫聲。","你發現一些閃亮的小石頭。","繼續前進，也許會遇到新夥伴！"][randi() % 4]

func _interact():
    if mode == "world":
        if player.distance_to(Vector2(235, 250)) < 90:
            coins += 5
            message = "你找到一個小寶箱！獲得 5 枚星幣。"
        else:
            _encounter()

func _encounter():
    mode = "battle"
    enemy_name = ["草芽獸", "泡泡團", "石甲仔"][randi() % 3]
    enemy_max_hp = 14 + randi_range(0, 8)
    enemy_hp = enemy_max_hp
    enemy_power = 3 + randi_range(0, 3)
    message = "野生的%s出現了！你要怎麼做？" % enemy_name

func _attack():
    if mode != "battle": return
    var damage = randi_range(5, 9) + team[0]["power"] - 5
    enemy_hp = max(0, enemy_hp - damage)
    if enemy_hp <= 0:
        coins += 8
        team[0]["level"] += 1
        team[0]["power"] += 1
        message = "勝利！獲得 8 枚星幣，焰尾狐升級了！"
        mode = "world"
    else:
        _enemy_attack()
    queue_redraw()

func _enemy_attack():
    var damage = enemy_power
    team[0]["hp"] = max(0, team[0]["hp"] - damage)
    if team[0]["hp"] <= 0:
        team[0]["hp"] = team[0]["max_hp"]
        mode = "world"
        message = "焰尾狐休息後恢復了體力。回去補給再挑戰吧。"
    else:
        message = "%s受到%d點傷害！" % [team[0]["name"], damage]

func _catch():
    if mode != "battle": return
    if enemy_hp > enemy_max_hp * 0.55:
        message = "怪獸還很有精神！先攻擊幾次，再試著收服。"
        _enemy_attack()
        return
    if randi() % 100 < 65:
        team.append({"name":enemy_name,"hp":18,"max_hp":18,"power":5,"level":1})
        caught += 1
        mode = "world"
        message = "收服成功！%s加入你的隊伍！" % enemy_name
    else:
        message = "差一點就成功了！再試一次。"
        _enemy_attack()
    queue_redraw()

func _use_potion():
    if potions <= 0:
        message = "沒有藥水了，可以之後在商店補充。"
    else:
        potions -= 1
        team[0]["hp"] = min(team[0]["max_hp"], team[0]["hp"] + 10)
        message = "使用藥水，焰尾狐恢復 10 點體力。"
        if mode == "battle":
            _enemy_attack()
    queue_redraw()

func _run_away():
    mode = "world"
    message = "你安全地離開了戰鬥。"

func _show_bag():
    mode = "bag"
    message = "背包：星幣 %d｜藥水 %d｜已收服 %d 隻怪獸。按「背包」或「互動」返回。" % [coins, potions, caught]

func _save_game():
    var data = {"player_x":player.x,"player_y":player.y,"steps":steps,"coins":coins,"potions":potions,"team":team,"caught":caught}
    var f = FileAccess.open("user://savegame.json", FileAccess.WRITE)
    f.store_string(JSON.stringify(data))
    saved_note = "已保存"
    message = "遊戲進度已保存到這台裝置。"
    queue_redraw()

func _draw():
    _draw_world()
    _draw_hud()
    if mode == "battle":
        _draw_battle()
    elif mode == "bag":
        draw_rect(Rect2(26, 180, 428, 360), Color(0.08,0.12,0.18,0.96))
        draw_rect(Rect2(26, 180, 428, 360), Color(0.9,0.85,0.55), false, 4)
        draw_string(ThemeDB.fallback_font, Vector2(52, 230), "冒險者背包", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color(1,0.9,0.55))
        draw_string(ThemeDB.fallback_font, Vector2(52, 285), "星幣：%d" % coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(52, 325), "藥水：%d" % potions, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(52, 365), "隊伍：%d 隻怪獸" % team.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(52, 405), "已收服：%d 隻" % caught, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(52, 470), "按下方「互動」返回冒險", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8,0.9,0.8))

func _draw_world():
    draw_rect(Rect2(0,0,W,H), Color("#87c9e8"))
    draw_rect(Rect2(0,90,W,540), Color("#8ccf76"))
    # distant hills
    for i in range(6):
        var x = i * 95 - 25
        draw_circle(Vector2(x,145), 72, Color("#6eb86c"))
        draw_circle(Vector2(x+45,158), 56, Color("#78c273"))
    # path
    var path = PackedVector2Array([Vector2(165,630),Vector2(190,330),Vector2(270,330),Vector2(330,630)])
    draw_colored_polygon(path, Color("#d9bd82"))
    # trees, bushes, flowers
    for p in [Vector2(50,210),Vector2(405,210),Vector2(70,360),Vector2(405,410),Vector2(120,520),Vector2(370,520)]:
        draw_rect(Rect2(p.x-5,p.y+15,10,24), Color("#795638"))
        draw_rect(Rect2(p.x-20,p.y-7,40,28), Color("#2e7848"))
        draw_rect(Rect2(p.x-15,p.y-20,30,28), Color("#3b9952"))
        draw_rect(Rect2(p.x-8,p.y-27,16,15), Color("#58b85f"))
    for i in range(34):
        var x = fposmod(i * 73 + 19, 465) + 7
        var y = fposmod(i * 47 + 121, 515) + 115
        draw_rect(Rect2(x,y,4,4), [Color("#fff0a5"),Color("#f7b4d3"),Color("#ffffff")][i%3])
    # treasure chest
    draw_rect(Rect2(207,232,48,29), Color("#8c4d2b"))
    draw_rect(Rect2(207,232,48,9), Color("#d68a3d"))
    draw_rect(Rect2(228,239,7,12), Color("#f8dc72"))
    # player sprite
    draw_rect(Rect2(player.x-9,player.y-15,18,20), Color("#f3c49a"))
    draw_rect(Rect2(player.x-11,player.y-20,22,10), Color("#6b4937"))
    draw_rect(Rect2(player.x-13,player.y-7,26,18), Color("#356cbd"))
    draw_rect(Rect2(player.x-9,player.y+11,7,9), Color("#3b354d"))
    draw_rect(Rect2(player.x+3,player.y+11,7,9), Color("#3b354d"))
    draw_rect(Rect2(player.x-5,player.y-9,3,3), Color("#20202b"))
    draw_rect(Rect2(player.x+3,player.y-9,3,3), Color("#20202b"))
    # little companion
    _draw_creature(Vector2(player.x+23,player.y+5), Color("#f08d55"), Color("#ffcf65"))
    draw_string(ThemeDB.fallback_font, Vector2(18,115), "星野草原", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#173e3a"))

func _draw_creature(pos: Vector2, body: Color, accent: Color):
    draw_rect(Rect2(pos.x-11,pos.y-9,22,19), body)
    draw_rect(Rect2(pos.x-8,pos.y-16,7,10), accent)
    draw_rect(Rect2(pos.x+2,pos.y-16,7,10), accent)
    draw_rect(Rect2(pos.x-6,pos.y-2,3,3), Color("#24212c"))
    draw_rect(Rect2(pos.x+4,pos.y-2,3,3), Color("#24212c"))
    draw_rect(Rect2(pos.x-4,pos.y+5,8,3), Color("#a84e3e"))

func _draw_hud():
    draw_rect(Rect2(12,12,456,78), Color(0.08,0.15,0.2,0.88))
    draw_rect(Rect2(12,12,456,78), Color("#f0d58b"), false, 3)
    draw_string(ThemeDB.fallback_font, Vector2(28,40), "星野馴獸師", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("#ffe9a3"))
    draw_string(ThemeDB.fallback_font, Vector2(28,68), "%s Lv.%d  HP %d/%d" % [team[0]["name"],team[0]["level"],team[0]["hp"],team[0]["max_hp"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(315,42), "★ %d" % coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffe9a3"))
    draw_string(ThemeDB.fallback_font, Vector2(315,67), saved_note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#bfe9c7"))
    draw_rect(Rect2(14,580,452,78), Color(0.08,0.13,0.18,0.88))
    draw_rect(Rect2(14,580,452,78), Color("#d9cb95"), false, 2)
    var msg = message
    if msg.length() > 47:
        msg = msg.substr(0,47) + "…"
    draw_string(ThemeDB.fallback_font, Vector2(28,610), msg, HORIZONTAL_ALIGNMENT_LEFT, 420, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(28,636), "步數 %d  |  收服 %d 隻" % [steps,caught], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#c8e8d0"))

func _draw_battle():
    draw_rect(Rect2(18,150,444,400), Color(0.08,0.12,0.18,0.96))
    draw_rect(Rect2(18,150,444,400), Color("#f0d58b"), false, 4)
    draw_string(ThemeDB.fallback_font, Vector2(42,190), "野生怪獸出現！", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#ffe9a3"))
    _draw_creature(Vector2(330,270), Color("#72b96c"), Color("#d9f18a"))
    draw_string(ThemeDB.fallback_font, Vector2(42,245), enemy_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(42,277), "HP %d / %d" % [enemy_hp,enemy_max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#c8e8d0"))
    draw_rect(Rect2(42,300,180,12), Color("#403a43"))
    draw_rect(Rect2(42,300,180.0 * enemy_hp / enemy_max_hp,12), Color("#77db73"))
    _draw_creature(Vector2(125,390), Color("#f08d55"), Color("#ffcf65"))
    draw_string(ThemeDB.fallback_font, Vector2(42,435), team[0]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(42,463), "HP %d / %d" % [team[0]["hp"],team[0]["max_hp"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#c8e8d0"))
    draw_string(ThemeDB.fallback_font, Vector2(42,510), "使用下方「攻擊」或「收服」", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#ffe9a3"))
