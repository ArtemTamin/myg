## EventBus.gd
## Глобальная система событий для связи между менеджерами и сущностями
## Godot 4.3+ синтаксис
## Использование: EventBus.signal_name.connect(callable) для подписки
##             EventBus.signal_name.emit(params) для отправки

extends Node

# ===== СИГНАЛЫ ТОРГОВЛИ И ЭКОНОМИКИ =====
signal prices_updated(item_id: String, new_price: float, location_id: String)
signal market_refreshed()
signal currency_exchanged(from_currency: String, to_currency: String, amount: float, rate: float)

# ===== СИГНАЛЫ ГИЛЬДИЙ И РЕПУТАЦИИ =====
signal reputation_changed(guild_id: String, character_id: String, old_value: int, new_value: int)
signal guild_quest_accepted(quest_id: String, guild_id: String)
signal guild_quest_completed(quest_id: String, guild_id: String, reward: Dictionary)
signal guild_rank_changed(guild_id: String, character_id: String, new_rank: int)

# ===== СИГНАЛЫ ТРАНСПОРТА =====
signal transport_rented(transport_id: String, renter_id: String, duration: int)
signal transport_returned(transport_id: String, renter_id: String)
signal transport_purchased(transport_id: String, owner_id: String)
signal transport_damage_changed(transport_id: String, old_durability: int, new_durability: int)

# ===== СИГНАЛЫ ФИНАНСОВ =====
signal credit_taken(credit_id: String, amount: float, interest_rate: float, due_date: int)
signal credit_payment_made(credit_id: String, amount: float, is_late: bool)
signal credit_defaulted(credit_id: String, penalty: float)
signal rent_paid(rental_id: String, amount: float, object_type: String)
signal finance_log_added(entry: Dictionary)

# ===== СИГНАЛЫ БОЕВОЙ СИСТЕМЫ =====
signal combat_started(participants: Array)
signal combat_ended(winner: Node2D, losers: Array)
signal entity_damaged(entity: Node2D, damage: float, damage_type: String)
signal entity_healed(entity: Node2D, heal_amount: float)
signal entity_died(entity: Node2D, killer: Node2D)
signal enemy_spawned(enemy: Node2D)
signal enemy_despawned(enemy: Node2D)

# ===== СИГНАЛЫ СТРОИТЕЛЬСТВА =====
signal building_placed(building_id: String, position: Vector2i, owner_id: String)
signal building_upgraded(building_id: String, new_level: int)
signal building_demolished(building_id: String, position: Vector2i)
signal building_production_complete(building_id: String, product_id: String, quantity: int)

# ===== СИГНАЛЫ ИГРОКА И NPC =====
signal player_interacted(target: Node2D, interaction_type: String)
signal npc_dialogue_started(npc_id: String, dialogue_id: String)
signal npc_dialogue_ended(npc_id: String)
signal inventory_changed(owner_id: String, item_id: String, quantity_change: int)
signal equipment_changed(owner_id: String, slot: String, item_id: String)

# ===== СИГНАЛЫ МИРА И ВРЕМЕНИ =====
signal time_passed(hours: float)
signal day_changed(day_number: int, season: String, weather: String)
signal weather_changed(old_weather: String, new_weather: String)
signal season_changed(old_season: String, new_season: String)
signal location_entered(location_id: String, location_name: String)
signal location_exited(location_id: String)

# ===== СИГНАЛЫ СОХРАНЕНИЯ/ЗАГРУЗКИ =====
signal game_saved(save_slot: int, success: bool)
signal game_loaded(save_slot: int, success: bool)
signal autosave_triggered()


func _ready() -> void:
	# Инициализация EventBus
	print("[EventBus] Система событий инициализирована")