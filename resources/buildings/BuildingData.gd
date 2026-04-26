## BuildingData.gd
## Resource-класс для данных зданий и построек
## Godot 4.3+ синтаксис
## Использование: Создать .tres файл через редактор (ПКМ → Create New → Resource)

extends Resource
class_name BuildingData

# ===== БАЗОВАЯ ИНФОРМАЦИЯ =====
@export_group("Основное")
@export var building_id: String = ""  # Уникальный ID (например: "house_small_01")
@export var building_name: String = ""  # Отображаемое имя
@export var description: String = ""  # Описание
@export var icon: Texture2D = null  # Иконка для UI строительства

# ===== ВИЗУАЛИЗАЦИЯ =====
@export_group("Визуализация")
@export var tile_id: int = 0  # ID тайла в TileMapLayer
@export var sprite_frames: SpriteFrames = null  # Для анимированных зданий
@export var size_x: int = 1  # Ширина в клетках сетки
@export var size_y: int = 1  # Высота в клетках сетки
@export var collision_shape: Shape2D = null  # Форма коллизии (опционально)

# ===== ЭКОНОМИКА =====
@export_group("Строительство и экономика")
@export var base_cost: float = 100.0  # Базовая стоимость строительства
@export var cost_currency_id: String = "gold"  # Валюта для оплаты
@export var build_time_minutes: int = 60  # Время постройки в минутах
@export var required_reputation: int = 0  # Требуемая репутация в гильдии
@export var required_guild_id: String = ""  # Требуемая гильдия (если есть)

# ===== ТИП ЗДАНИЯ =====
@export_group("Тип и функция")
@export_enum("Residential", "Commercial", "Industrial", "Agricultural", "Storage", "Defense", "Special") var building_type: String = "Residential"
@export var is_upgradeable: bool = true  # Можно ли улучшать
@export var max_level: int = 3  # Максимальный уровень улучшения
@export var upgrade_path: Array[String] = []  # IDs следующих уровней улучшения

# ===== ПРОИЗВОДСТВО =====
@export_group("Производство")
@export var produces_items: bool = false  # Производит ли товары
@export var production_rate_per_hour: float = 1.0  # Единиц продукции в час
@export var output_item_ids: Array[String] = []  # IDs производимых предметов
@export var input_item_ids: Array[String] = []  # IDs требуемых ресурсов
@export var storage_capacity: int = 100  # Вместимость склада
@export var requires_worker: bool = false  # Требуется ли работник
@export var max_workers: int = 1  # Максимум работников

# ===== ЖИЛОЕ ЗДАНИЕ =====
@export_group("Жилые здания")
@export var housing_capacity: int = 0  # Сколько жителей размещает
@export var rent_income_per_day: float = 0.0  # Доход от аренды в день
@export var comfort_rating: int = 1  # Рейтинг комфорта (влияет на привлекательность)

# ===== ТОРГОВОЕ ЗДАНИЕ =====
@export_group("Торговля")
@export var merchant_slots: int = 0  # Количество торговых мест
@export var trade_bonus_percent: float = 0.0  # Бонус к торговле (%)
@export var allowed_trade_categories: Array[String] = []  # Категории товаров для торговли

# ===== МАСТЕРСКАЯ / КРАФТ =====
@export_group("Ремесло")
@export var crafting_recipes: Array[String] = []  # IDs доступных рецептов
@export var craft_speed_multiplier: float = 1.0  # Множитель скорости крафта
@export var quality_bonus: int = 0  # Бонус к качеству изделий

# ===== ОБОРОНА =====
@export_group("Оборона")
@export var defensive_value: int = 0  # Защитная ценность
@export var can_house_guards: bool = false  # Можно ли разместить охрану
@export var guard_capacity: int = 0  # Максимум охранников
@export var tower_range: float = 0.0  # Дальность обзора/атаки (для башен)

# ===== РАСПОЛОЖЕНИЕ =====
@export_group("Размещение")
@export var allowed_terrain_types: Array[String] = ["grass", "dirt"]  # Допустимые типы местности
@export var requires_road_access: bool = false  # Требуется ли доступ к дороге
@export var requires_water_access: bool = false  # Требуется ли доступ к воде
@export var cannot_be_adjacent_to: Array[String] = []  # IDs зданий, рядом с которыми нельзя строить

# ===== УЛУЧШЕНИЯ =====
@export_group("Улучшения")
@export var upgrade_cost_multiplier: float = 1.5  # Множитель стоимости улучшения
@export var upgrade_time_multiplier: float = 1.2  # Множитель времени улучшения
@export var benefits_per_level: Dictionary = {}  # Бонусы за уровень: { "production": 0.1, "capacity": 10 }

# ===== МЕТОДЫ =====
## Получить стоимость улучшения для уровня
func get_upgrade_cost(current_level: int) -> float:
	if not is_upgradeable or current_level >= max_level:
		return -1.0
	
	var multiplier = pow(upgrade_cost_multiplier, current_level)
	return base_cost * multiplier


## Получить время улучшения для уровня
func get_upgrade_time(current_level: int) -> int:
	if not is_upgradeable or current_level >= max_level:
		return -1
	
	var multiplier = pow(upgrade_time_multiplier, current_level)
	return int(build_time_minutes * multiplier)


## Проверить возможность размещения на тайле
func can_place_on_tile(terrain_type: String, adjacent_buildings: Array[String]) -> bool:
	# Проверка типа местности
	if terrain_type not in allowed_terrain_types:
		return false
	
	# Проверка соседства с запрещёнными зданиями
	for building_id in cannot_be_adjacent_to:
		if building_id in adjacent_buildings:
			return false
	
	return true


## Получить производство в час для уровня
func get_production_per_hour(level: int = 1) -> float:
	if not produces_items:
		return 0.0
	
	var bonus = benefits_per_level.get("production", 0.0)
	return production_rate_per_hour * (1.0 + bonus * (level - 1))


## Получить вместимость для уровня
func get_storage_capacity_for_level(level: int = 1) -> int:
	var bonus = benefits_per_level.get("capacity", 0)
	return storage_capacity + int(bonus * (level - 1))


## Валидация данных
func validate() -> bool:
	if building_id.is_empty():
		push_error("BuildingData: пустой building_id")
		return false
	
	if base_cost <= 0:
		push_warning("BuildingData '", building_id, "': стоимость <= 0")
	
	if is_upgradeable and max_level < 1:
		push_error("BuildingData '", building_id, "': max_level < 1")
		return false
	
	return true


## Конвертация в словарь для сохранения
func to_dict() -> Dictionary:
	return {
		"building_id": building_id,
		"building_name": building_name,
		"building_type": building_type,
		"tile_id": tile_id,
		"size_x": size_x,
		"size_y": size_y,
		"base_cost": base_cost,
		"is_upgradeable": is_upgradeable,
		"max_level": max_level,
		"produces_items": produces_items,
		"production_rate_per_hour": production_rate_per_hour,
		"housing_capacity": housing_capacity,
		"storage_capacity": storage_capacity
	}


## Загрузка из словаря
func from_dict(data: Dictionary) -> void:
	building_id = data.get("building_id", "")
	building_name = data.get("building_name", "")
	building_type = data.get("building_type", "Residential")
	tile_id = data.get("tile_id", 0)
	size_x = data.get("size_x", 1)
	size_y = data.get("size_y", 1)
	base_cost = data.get("base_cost", 100.0)
	is_upgradeable = data.get("is_upgradeable", true)
	max_level = data.get("max_level", 3)
	produces_items = data.get("produces_items", false)
	production_rate_per_hour = data.get("production_rate_per_hour", 1.0)
	housing_capacity = data.get("housing_capacity", 0)
	storage_capacity = data.get("storage_capacity", 100)