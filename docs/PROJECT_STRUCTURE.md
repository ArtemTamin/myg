# Структура проекта Godot 4.3: Trade & Exploration RPG

## 📁 Дерево файлов и папок

```
/workspace/
├── project.godot              # Конфигурация проекта (Autoload, input, слои)
├── README.md                  # Документация и ТЗ
│
├── autoload/                  # Глобальные менеджеры (Singleton)
│   ├── EventBus.gd           # Система событий (сигналы для связи)
│   └── GameManager.gd        # Состояние игры: время, погода, пауза
│
├── managers/                  # Менеджеры систем (добавляются в Autoload)
│   ├── MarketManager.gd      # Динамическая торговля и цены
│   ├── CurrencyManager.gd    # Валюты и конвертация
│   ├── GuildManager.gd       # Гильдии, репутация, квесты
│   ├── TransportManager.gd   # Транспорт, аренда, логистика
│   ├── FinanceManager.gd     # Кредиты, аренда, финансовый лог
│   ├── CombatManager.gd      # Боевая система, ИИ врагов
│   └── SaveManager.gd        # Сохранение/загрузка (JSON)
│
├── resources/                 # Resource-данные (.tres файлы)
│   ├── items/
│   │   └── ItemData.gd       # Класс данных предметов
│   ├── currencies/
│   │   └── CurrencyData.gd   # Класс данных валют
│   ├── buildings/
│   │   └── BuildingData.gd   # Класс данных зданий
│   ├── quests/
│   │   └── QuestData.gd      # Класс данных квестов
│   ├── guilds/
│   │   └── GuildData.gd      # Класс данных гильдий
│   ├── transport/
│   │   └── TransportData.gd  # Класс данных транспорта
│   └── combat/
│       └── EnemyData.gd      # Класс данных врагов
│
├── scenes/                    # Сцены (.tscn файлы)
│   ├── main/                 # Главная сцена мира
│   ├── player/               # Сцена игрока
│   ├── npcs/                 # NPC и торговцы
│   ├── enemies/              # Враги и боссы
│   ├── buildings/            # Здания и постройки
│   ├── transport/            # Транспорт (повозки, корабли)
│   └── ui/                   # UI элементы (торговля, инвентарь, квесты)
│
├── scripts/                   # Общие скрипты
│   ├── entities/             # Сущности (Player, NPC, Enemy)
│   │   ├── Player.gd
│   │   ├── NPC.gd
│   │   └── Enemy.gd
│   ├── components/           # Компоненты (Health, Inventory)
│   │   ├── HealthComponent.gd
│   │   └── InventoryComponent.gd
│   └── utils/                # Утилиты и константы
│       └── Constants.gd
│
├── data/                     # Данные конфигурации
│   ├── save_configs/         # Шаблоны сохранений
│   │   └── save_template.json
│   └── localization/         # Локализация (CSV/JSON)
│
└── assets/                   # Ресурсы (спрайты, аудио, шрифты)
    ├── sprites/
    ├── audio/
    └── fonts/
```

---

## 🔧 Настройка в редакторе Godot 4.3+

### Шаг 1: Открыть проект
1. Запустите Godot 4.3+
2. Нажмите "Import" и укажите путь к `project.godot`

### Шаг 2: Проверка Autoload
Проект уже настроен. Проверьте:  
`Project Settings → Autoload`  
Все менеджеры из `/autoload` и `/managers` должны быть в списке.

### Шаг 3: Создание Resource-данных (.tres)
Для каждого типа данных создайте ресурсы через редактор:

**Пример создания ItemData:**
1. В панели FileSystem нажмите ПКМ на `resources/items/`
2. Выберите `Create New → Resource`
3. В поле `Class` выберите `ItemData` (или введите имя класса)
4. Назовите файл, например `apple.tres`
5. Заполните поля в инспекторе (id, name, base_price, type, etc.)

Повторите для:
- `CurrencyData` → `resources/currencies/`
- `BuildingData` → `resources/buildings/`
- `QuestData` → `resources/quests/`
- `GuildData` → `resources/guilds/`
- `TransportData` → `resources/transport/`
- `EnemyData` → `resources/combat/`

### Шаг 4: Настройка TileMapLayer для строительства
1. Создайте новую сцену `scenes/main/Main.tscn` (Node2D)
2. Добавьте ноду `TileMapLayer`
3. Создайте `TileSet` ресурс
4. Настройте сетку (рекомендуется 64x64 или 32x32)
5. Добавьте тайлы для земли, дорог, зданий

### Шаг 5: Настройка Camera2D для игрока
1. Откройте сцену игрока `scenes/player/Player.tscn`
2. Добавьте ноду `Camera2D` как дочернюю к игроку
3. Включите `Current = true`
4. Настройте `Zoom` и `Limit` для границ карты

### Шаг 6: Настройка NavigationRegion2D для ИИ
1. Для сцены с врагами добавьте `NavigationRegion2D`
2. Создайте `NavigationPolygon`
3. Нарисуйте полигон проходимой области

---

## 📝 Примеры использования

### Подписка на события (в любом скрипте)
```gdscript
func _ready() -> void:
    EventBus.prices_updated.connect(_on_price_changed)
    EventBus.day_changed.connect(_on_day_changed)

func _on_price_changed(item_id: String, new_price: float, location_id: String) -> void:
    print("Цена ", item_id, " изменилась: ", new_price)
```

### Получение текущей цены
```gdscript
var price = MarketManager.get_current_price("food_apple", "city_capital")
```

### Изменение репутации
```gdscript
GuildManager.change_reputation("merchants_guild", "player_1", 10)
```

### Сохранение игры
```gdscript
SaveManager.save_game(1)  # Слот сохранения №1
```

---

## ✅ Чек-лист после настройки

- [ ] Проект открывается в Godot 4.3+ без ошибок
- [ ] Все 8 менеджеров добавлены в Autoload
- [ ] Создан хотя бы один тестовый `.tres` ресурс (например, предмет)
- [ ] Главная сцена `Main.tscn` существует и содержит TileMapLayer
- [ ] Сцена игрока содержит CharacterBody2D + Camera2D
- [ ] Input Map настроен (WASD движение, E взаимодействие)
- [ ] При запуске в консоли видно сообщения от менеджеров

---

## 🚀 Следующий шаг

Реализация **ядра данных**: создание всех Resource-классов (`ItemData`, `CurrencyData`, `BuildingData`, etc.) и наполнение тестовыми данными.
