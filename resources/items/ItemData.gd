## ItemData.gd
## Resource-класс для данных предметов
## Godot 4.3+ синтаксис
## Использование: Создать .tres файл через редактор (ПКМ → Create New → Resource)

extends Resource
class_name ItemData

# ===== БАЗОВАЯ ИНФОРМАЦИЯ =====
@export_group("Основное")
@export var item_id: String = ""  # Уникальный ID (например: "food_apple")
@export var item_name: String = ""  # Отображаемое имя
@export var description: String = ""  # Описание предмета
@export var icon: Texture2D = null  # Иконка для UI

# ===== КАТЕГОРИЗАЦИЯ =====
@export_group("Категория")
@export_enum("Food", "Seeds", "Tools", "Weapons", "Armor", "Materials", "Luxury", "Quest", "Other") var item_type: String = "Other"
@export var tags: Array[String] = []  # Теги для фильтрации (например: ["perishable", "tradeable"])

# ===== ЭКОНОМИКА =====
@export_group("Экономика")
@export var base_price: float = 10.0  # Базовая цена в золоте
@export var stack_size: int = 99  # Максимум в стаке
@export var weight: float = 0.5  # Вес в единицах грузоподъёмности

# ===== ПРЕДМЕТЫ ЕДЫ =====
@export_group("Еда и потребление")
@export var is_consumable: bool = false
@export var food_value: int = 0  # Восстановление голода
@export var health_value: int = 0  # Восстановление здоровья
@export var duration_seconds: float = 0.0  # Длительность эффекта (если есть)

# ===== СЕМЕНА И ВЫРАЩИВАНИЕ =====
@export_group("Сельское хозяйство")
@export var is_seed: bool = false
@export var grown_item_id: String = ""  # ID предмета после выращивания
@export var grow_time_days: int = 7  # Дней до созревания
@export var required_season: String = ""  # Требуемый сезон (Spring, Summer, etc.)

# ===== ТОРГОВЛЯ =====
@export_group("Торговые параметры")
@export var price_volatility: float = 0.2  # Колебания цены (0.0-1.0)
@export var demand_modifier: float = 1.0  # Модификатор спроса
@export var trade_skill_required: int = 0  # Требуемый навык торговли

# ===== КВЕСТОВЫЕ ПРЕДМЕТЫ =====
@export_group("Квесты")
@export var is_quest_item: bool = false
@export var quest_id: String = ""  # Связанный квест
@export var can_be_sold: bool = true  # Можно ли продать торговцу

# ===== ПРОИЗВОДСТВО =====
@export_group("Крафт и производство")
@export var craft_time_minutes: int = 0  # Время крафта в минутах
@export var required_building_id: String = ""  # Требуемое здание для крафта
@export var recipe: Dictionary = {}  # Рецепт: { "item_id": quantity }

# ===== МЕТОДЫ =====
## Получить общую стоимость стака
func get_stack_total_cost(quantity: int = 1) -> float:
	return base_price * quantity


## Проверить, можно ли складывать с другим предметом
func can_stack_with(other: ItemData) -> bool:
	return other.item_id == item_id and stack_size > 1


## Получить тип предмета для модификаторов рынка
func get_market_type() -> String:
	if is_seed:
		return "crops_seed"
	elif is_consumable and food_value > 0:
		return "food"
	elif item_type == "Luxury":
		return "luxury_goods"
	else:
		return item_type.to_lower()


## Валидация данных (вызывается при загрузке)
func validate() -> bool:
	if item_id.is_empty():
		push_error("ItemData: пустой item_id")
		return false
	
	if item_name.is_empty():
		push_warning("ItemData '", item_id, "': пустое имя")
	
	if base_price <= 0:
		push_warning("ItemData '", item_id, "': цена <= 0")
	
	return true


## Конвертация в словарь для сохранения
func to_dict() -> Dictionary:
	return {
		"item_id": item_id,
		"item_name": item_name,
		"item_type": item_type,
		"base_price": base_price,
		"stack_size": stack_size,
		"weight": weight,
		"is_consumable": is_consumable,
		"food_value": food_value,
		"is_seed": is_seed,
		"grown_item_id": grown_item_id,
		"is_quest_item": is_quest_item,
		"tags": tags
	}


## Загрузка из словаря (для динамического создания)
func from_dict(data: Dictionary) -> void:
	item_id = data.get("item_id", "")
	item_name = data.get("item_name", "")
	item_type = data.get("item_type", "Other")
	base_price = data.get("base_price", 10.0)
	stack_size = data.get("stack_size", 99)
	weight = data.get("weight", 0.5)
	is_consumable = data.get("is_consumable", false)
	food_value = data.get("food_value", 0)
	is_seed = data.get("is_seed", false)
	grown_item_id = data.get("grown_item_id", "")
	is_quest_item = data.get("is_quest_item", false)
	tags = data.get("tags", [])