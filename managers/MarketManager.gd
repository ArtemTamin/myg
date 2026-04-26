## MarketManager.gd
## Менеджер динамической торговли и экономики
## Godot 4.3+ синтаксис
## Добавлен в Autoload через project.godot
## Обновление цен: каждый игровой день или по событию

extends Node

# ===== БАЗОВЫЕ ДАННЫЕ =====
# Хранение цен: { item_id: { location_id: base_price } }
var _base_prices: Dictionary = {}
# Текущие цены с модификаторами: { item_id: { location_id: current_price } }
var _current_prices: Dictionary = {}
# Модификаторы цен: { item_id: modifier_value }
var _price_modifiers: Dictionary = {}

# ===== КОНФИГУРАЦИЯ =====
@export var default_price_variance: float = 0.2  # ±20% вариация базовой цены
@export var max_price_multiplier: float = 3.0  # Максимальный множитель цены
@export var min_price_multiplier: float = 0.3  # Минимальный множитель цены

# ===== ССЫЛКИ НА ДАННЫЕ (Resource) =====
# Загружаются через ResourceLoader или создаются вручную в редакторе
# var item_database: Array[ItemData] = []


func _ready() -> void:
	print("[MarketManager] Инициализация менеджера рынка")
	_connect_signals()


func _connect_signals() -> void:
	# Подписка на события изменения факторов влияния
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.location_entered.connect(_on_location_entered)


# ===== ИНИЦИАЛИЗАЦИЯ ЦЕН =====
## Установка базовых цен для предметов
func set_base_price(item_id: String, location_id: String, price: float) -> void:
	if not _base_prices.has(item_id):
		_base_prices[item_id] = {}
		_current_prices[item_id] = {}
	
	_base_prices[item_id][location_id] = price
	
	# Инициализация текущей цены
	_refresh_item_price(item_id, location_id)


## Массовая установка базовых цен из конфига
func initialize_prices_from_config(prices_config: Dictionary) -> void:
	for item_id in prices_config.keys():
		for location_id in prices_config[item_id].keys():
			set_base_price(item_id, location_id, prices_config[item_id][location_id])
	
	refresh_all_prices()


# ===== РАСЧЁТ ТЕКУЩИХ ЦЕН =====
## Обновление всех цен (вызывается каждый день)
func refresh_all_prices() -> void:
	for item_id in _base_prices.keys():
		for location_id in _base_prices[item_id].keys():
			_refresh_item_price(item_id, location_id)
	
	EventBus.market_refreshed.emit()
	print("[MarketManager] Цены обновлены")


## Обновление цены конкретного предмета в локации
func _refresh_item_price(item_id: String, location_id: String) -> void:
	var base_price = _base_prices[item_id][location_id]
	
	# Расчёт модификаторов
	var modifier = _calculate_price_modifier(item_id, location_id)
	
	# Применение ограничений
	modifier = clamp(modifier, min_price_multiplier, max_price_multiplier)
	
	# Финальная цена
	var final_price = base_price * modifier
	_current_prices[item_id][location_id] = round(final_price * 100) / 100.0  # Округление до копеек
	
	# Уведомление UI
	EventBus.prices_updated.emit(item_id, _current_prices[item_id][location_id], location_id)


## Расчёт общего модификатора цены
func _calculate_price_modifier(item_id: String, location_id: String) -> float:
	var modifier = 1.0
	
	# 1. Сезонный модификатор
	modifier *= _get_season_modifier(item_id)
	
	# 2. Модификатор погоды
	modifier *= _get_weather_modifier(item_id)
	
	# 3. Модификатор времени суток
	modifier *= _get_time_of_day_modifier(item_id)
	
	# 4. Модификатор локации (спрос/предложение)
	modifier *= _get_location_modifier(item_id, location_id)
	
	# 5. Модификатор репутации игрока (если есть активный игрок)
	modifier *= _get_reputation_modifier(item_id)
	
	# 6. Случайные события
	modifier *= _get_random_event_modifier(item_id)
	
	# 7. Индивидуальные модификаторы предмета
	if _price_modifiers.has(item_id):
		modifier *= _price_modifiers[item_id]
	
	return modifier


# ===== МОДИФИКАТОРЫ =====
## Сезонный модификатор (пример: еда дешевле осенью, тёплая одежда дороже зимой)
func _get_season_modifier(item_id: String) -> float:
	var season = GameManager.current_season
	var item_type = _get_item_type(item_id)  # Нужно реализовать или загружать из ItemData
	
	match item_type:
		"food":
			match season:
				GameManager.Season.AUTUMN: return 0.8  # Урожай, дешевле
				GameManager.Season.WINTER: return 1.3  # Дефицит, дороже
				_: return 1.0
		"warm_clothing":
			match season:
				GameManager.Season.WINTER: return 1.5
				GameManager.Season.SUMMER: return 0.7
				_: return 1.0
		"crops_seed":
			match season:
				GameManager.Season.SPRING: return 1.2  # Высокий спрос на семена
				GameManager.Season.WINTER: return 0.6  # Не сезон
				_: return 1.0
		_:
			return 1.0


## Модификатор погоды (пример: зонты дороже в дождь, еда для путешествий в шторм)
func _get_weather_modifier(item_id: String) -> float:
	var weather = GameManager.current_weather
	var item_type = _get_item_type(item_id)
	
	match item_type:
		"rain_gear":
			match weather:
				GameManager.Weather.RAIN: return 1.4
				GameManager.Weather.STORM: return 1.6
				_: return 1.0
		"travel_food":
			match weather:
				GameManager.Weather.STORM: return 1.3
				GameManager.Weather.SNOW: return 1.2
				_: return 1.0
		_:
			return 1.0


## Модификатор времени суток (пример: еда в тавернах дороже вечером)
func _get_time_of_day_modifier(item_id: String) -> float:
	var hour = GameManager.current_hour
	var item_type = _get_item_type(item_id)
	
	match item_type:
		"tavern_meal":
			if hour >= 18 or hour < 2:  # Вечер/ночь
				return 1.3
			elif hour >= 12 and hour < 15:  # Обед
				return 1.1
			else:
				return 0.9  # Утро, низкий спрос
		"breakfast":
			if hour >= 6 and hour < 10:
				return 1.2
			else:
				return 0.8
		_:
			return 1.0


## Модификатор локации (город vs деревня, порты и т.д.)
func _get_location_modifier(item_id: String, location_id: String) -> float:
	# Здесь должна быть логика на основе данных локации
	# Пример упрощённой реализации:
	var location_type = _get_location_type(location_id)  # "city", "village", "port", etc.
	var item_type = _get_item_type(item_id)
	
	match item_type:
		"luxury_goods":
			match location_type:
				"city": return 1.2  # В городах выше спрос
				"village": return 0.8
				_: return 1.0
		"fish":
			match location_type:
				"port": return 0.7  # В портах дешевле
				"city": return 1.1
				_: return 1.0
		_:
			return 1.0


## Модификатор репутации игрока (высокая репутация = скидки)
func _get_reputation_modifier(item_id: String) -> float:
	# Заглушка: будет реализовано через GuildManager
	# Пример: если репутация > 80, скидка 10%
	var player_reputation = 50  # TODO: получить из GuildManager или GameManager
	
	if player_reputation >= 80:
		return 0.9
	elif player_reputation <= 20:
		return 1.15  # Наценка для игроков с плохой репутацией
	
	return 1.0


## Случайные события (праздники, войны, караваны)
func _get_random_event_modifier(item_id: String) -> float:
	# TODO: Реализовать систему случайных событий
	# Пример: "Праздник урожая" → еда дешевле на 15%
	return 1.0


# ===== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =====
## Получение типа предмета (заглушка, заменить на загрузку из ItemData)
func _get_item_type(item_id: String) -> String:
	# TODO: Загружать из ресурса ItemData
	# Временная реализация по префиксу ID
	if item_id.begins_with("food_"):
		return "food"
	elif item_id.begins_with("seed_"):
		return "crops_seed"
	elif item_id.begins_with("clothes_warm_"):
		return "warm_clothing"
	elif item_id.begins_with("gear_rain_"):
		return "rain_gear"
	elif item_id.begins_with("luxury_"):
		return "luxury_goods"
	elif item_id.begins_with("fish_"):
		return "fish"
	elif item_id.begins_with("meal_"):
		return "tavern_meal"
	else:
		return "generic"


## Получение типа локации (заглушка)
func _get_location_type(location_id: String) -> String:
	# TODO: Загружать из данных локации
	if location_id.begins_with("city_"):
		return "city"
	elif location_id.begins_with("village_"):
		return "village"
	elif location_id.begins_with("port_"):
		return "port"
	else:
		return "default"


# ===== ПУБЛИЧНЫЕ МЕТОДЫ ДЛЯ ТОРГОВЛИ =====
## Получить текущую цену предмета в локации
func get_current_price(item_id: String, location_id: String) -> float:
	if _current_prices.has(item_id) and _current_prices[item_id].has(location_id):
		return _current_prices[item_id][location_id]
	
	# Если цена не найдена, вернуть базовую или 0
	if _base_prices.has(item_id) and _base_prices[item_id].has(location_id):
		return _base_prices[item_id][location_id]
	
	return 0.0


## Получить базовую цену
func get_base_price(item_id: String, location_id: String) -> float:
	if _base_prices.has(item_id) and _base_prices[item_id].has(location_id):
		return _base_prices[item_id][location_id]
	return 0.0


## Установить индивидуальный модификатор для предмета (временное событие)
func set_item_modifier(item_id: String, modifier: float, duration_days: int = -1) -> void:
	_price_modifiers[item_id] = modifier
	
	if duration_days > 0:
		# TODO: Добавить таймер для сброса модификатора
		pass


## Сбросить модификатор предмета
func clear_item_modifier(item_id: String) -> void:
	if _price_modifiers.has(item_id):
		_price_modifiers.erase(item_id)
		refresh_all_prices()


# ===== СОБЫТИЯ =====
func _on_day_changed(day_number: int, season: String, weather: String) -> void:
	refresh_all_prices()


func _on_weather_changed(old_weather: String, new_weather: String) -> void:
	# Пересчитать цены, зависящие от погоды
	refresh_all_prices()


func _on_season_changed(old_season: String, new_season: String) -> void:
	refresh_all_prices()


func _on_location_entered(location_id: String, location_name: String) -> void:
	# Можно обновить UI торговли при входе в новую локацию
	pass


# ===== СОХРАНЕНИЕ/ЗАГРУЗКА =====
func get_market_state() -> Dictionary:
	return {
		"base_prices": _base_prices.duplicate(true),
		"current_prices": _current_prices.duplicate(true),
		"modifiers": _price_modifiers.duplicate(true)
	}


func load_market_state(state: Dictionary) -> void:
	_base_prices = state.get("base_prices", {}).duplicate(true)
	_current_prices = state.get("current_prices", {}).duplicate(true)
	_price_modifiers = state.get("modifiers", {}).duplicate(true)