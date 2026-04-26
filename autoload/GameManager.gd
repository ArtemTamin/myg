## GameManager.gd
## Главный менеджер состояния игры: время, погода, текущая локация, пауза
## Godot 4.3+ синтаксис
## Добавлен в Autoload через project.godot

extends Node

# ===== КОНСТАНТЫ ВРЕМЕНИ =====
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAYS_PER_SEASON: int = 30  # 120 дней в году

# ===== ПЕРЕЧИСЛЕНИЯ =====
enum Season { SPRING, SUMMER, AUTUMN, WINTER }
enum Weather { CLEAR, RAIN, STORM, SNOW, FOG }

# ===== ЭКСПОРТИРУЕМЫЕ ПЕРЕМЕННЫЕ =====
@export var time_scale: float = 1.0  # Скорость течения времени (1.0 = реальное время)
@export var start_hour: float = 8.0  # Начальное время дня (8:00)
@export var start_day: int = 1  # Начальный день года
@export var start_season: Season = Season.SPRING
@export var start_weather: Weather = Weather.CLEAR

# ===== СОСТОЯНИЕ ИГРЫ =====
var current_hour: float = start_hour  # Текущее время в часах (0-24)
var current_day: int = start_day  # Текущий день года (1-120)
var current_season: Season = start_season
var current_weather: Weather = start_weather
var current_location_id: String = ""  # ID текущей локации
var is_paused: bool = false  # Состояние паузы

# ===== ССЫЛКИ НА МЕНЕДЖЕРЫ (Autoload) =====
# Доступны глобально через EventBus и прямые ссылки

# ===== ИНИЦИАЛИЗАЦИЯ =====
func _ready() -> void:
	print("[GameManager] Инициализация менеджера игры")
	_set_season_by_day()


func _process(delta: float) -> void:
	if is_paused:
		return
	
	# Обновление времени с учётом time_scale
	current_hour += delta * time_scale
	
	if current_hour >= HOURS_PER_DAY:
		_on_day_changed()
	
	# Эмит сигнала о прошедшем времени
	EventBus.time_passed.emit(delta)


# ===== МЕТОДЫ УПРАВЛЕНИЯ ВРЕМЕНЕМ =====
## Переход к новому дню
func _on_day_changed() -> void:
	var old_season = current_season
	current_hour = fmod(current_hour, HOURS_PER_DAY)
	current_day += 1
	
	if current_day > DAYS_PER_SEASON * 4:
		current_day = 1  # Новый год
	
	_set_season_by_day()
	
	# Проверка смены сезона
	if current_season != old_season:
		EventBus.season_changed.emit(Season.keys()[old_season], Season.keys()[current_season])
	
	# Генерация новой погоды (можно заменить на более сложную логику)
	_generate_daily_weather()
	
	# Эмит события смены дня
	EventBus.day_changed.emit(current_day, Season.keys()[current_season], Weather.keys()[current_weather])
	
	# Обновление рыночных цен каждый день
	if MarketManager:
		MarketManager.refresh_all_prices()


## Установка сезона на основе текущего дня
func _set_season_by_day() -> void:
	var day_in_year = (current_day - 1) % (DAYS_PER_SEASON * 4)
	var season_index = day_in_year / DAYS_PER_SEASON
	current_season = Season.values()[int(season_index)]


## Генерация погоды на день (случайная с весами по сезону)
func _generate_daily_weather() -> void:
	var weather_weights = _get_weather_weights_for_season()
	var roll = randf()
	var cumulative = 0.0
	
	for weather_key in weather_weights.keys():
		cumulative += weather_weights[weather_key]
		if roll <= cumulative:
			var old_weather = current_weather
			current_weather = Weather.keys().find(weather_key) as Weather
			if old_weather != current_weather:
				EventBus.weather_changed.emit(Weather.keys()[old_weather], Weather.keys()[current_weather])
			break


## Веса погоды по сезону (настраиваемые)
func _get_weather_weights_for_season() -> Dictionary:
	match current_season:
		Season.SPRING:
			return {"CLEAR": 0.5, "RAIN": 0.35, "STORM": 0.05, "FOG": 0.1}
		Season.SUMMER:
			return {"CLEAR": 0.7, "RAIN": 0.15, "STORM": 0.1, "FOG": 0.05}
		Season.AUTUMN:
			return {"CLEAR": 0.45, "RAIN": 0.3, "STORM": 0.05, "FOG": 0.2}
		Season.WINTER:
			return {"CLEAR": 0.4, "SNOW": 0.4, "STORM": 0.1, "FOG": 0.1}
		_:
			return {"CLEAR": 0.6, "RAIN": 0.3, "FOG": 0.1}


# ===== МЕТОДЫ УПРАВЛЕНИЯ ПАУЗОЙ =====
func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	print("[GameManager] Игра на паузе")


func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	print("[GameManager] Игра возобновлена")


func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()


# ===== МЕТОДЫ УПРАВЛЕНИЯ ЛОКАЦИЕЙ =====
func enter_location(location_id: String, location_name: String) -> void:
	var old_location = current_location_id
	current_location_id = location_id
	EventBus.location_entered.emit(location_id, location_name)
	print("[GameManager] Вход в локацию: ", location_name)


func exit_location(location_id: String) -> void:
	current_location_id = ""
	EventBus.location_exited.emit(location_id)
	print("[GameManager] Выход из локации: ", location_id)


# ===== ГЕТТЕРЫ ДЛЯ ДРУГИХ СИСТЕМ =====
func get_current_time_string() -> String:
	var hours = int(current_hour)
	var minutes = int(fmod(current_hour, 1.0) * MINUTES_PER_HOUR)
	return "%02d:%02d" % [hours, minutes]


func get_season_name() -> String:
	return Season.keys()[current_season]


func get_weather_name() -> String:
	return Weather.keys()[current_weather]


func get_game_state() -> Dictionary:
	return {
		"hour": current_hour,
		"day": current_day,
		"season": current_season,
		"weather": current_weather,
		"location": current_location_id,
		"is_paused": is_paused
	}


func load_game_state(state: Dictionary) -> void:
	current_hour = state.get("hour", start_hour)
	current_day = state.get("day", start_day)
	current_season = state.get("season", start_season) as Season
	current_weather = state.get("weather", start_weather) as Weather
	current_location_id = state.get("location", "")
	is_paused = state.get("is_paused", false)
	_set_season_by_day()