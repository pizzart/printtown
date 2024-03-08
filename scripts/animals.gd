extends Node

class Animal:
	const SATISFACTION_MIN = 0.9
	#const PUNISHMENT = 0.15
	var texture: Texture2D
	var animal_name: StringName
	# 0 to 1
	var satisfaction: float # self explanatory. over 90% -> can be stickered
	var mood: float # the willingness to be petted
	var guard: float # the willingness to bite
	var cooperation: float # the boost given to satisfaction when petted
	# any int
	var damage: int # damage it deals to the player
	var health: int # the health
	var init_health: int
	# after it's been stickered
	var convincing: float
	var healing: int
	var preference: Global.RPS
	
	func _init(_texture: Texture2D, _animal_name: StringName, _mood: float, _guard: float, _cooperation: float, _health: int, _damage: int, _convincing: float, _healing: int):
		randomize()
		texture = _texture
		animal_name = _animal_name
		mood = _mood
		guard = _guard
		cooperation = _cooperation
		health = _health
		init_health = _health
		damage = _damage
		convincing = _convincing
		healing = _healing
		satisfaction = 0
		preference = randi_range(0, 2) as Global.RPS
	
	func add_mood(amount: float):
		mood = clampf(mood + amount * cooperation, 0.0, 1.0)
	
	func add_guard(amount: float):
		guard = clampf(guard + amount * cooperation, 0.0, 1.0)
	
	func add_satisfaction(amount: float):
		satisfaction = clampf(satisfaction + amount * cooperation, 0.0, 1.0)
	
	#func pet():
		#mood = minf(mood + randf_range(cooperation / 2, cooperation + 0.2), 1.0)
		#if randf() <= mood:
			#satisfaction += cooperation * (1.0 + mood)
		#else:
			#if randf() <= guard:
				#mood = minf(mood + cooperation * 0.3, 1.0)
				#guard = maxf(guard - cooperation, 0.0)
				#return damage
			#else:
				#pass
		#return 0
	#
	#func kick():
		#mood = maxf(mood - randf_range(cooperation * 0.5, cooperation + 0.2), 0.0)
		#if randf() <= guard: # successful kick
			#guard = maxf(guard - cooperation, 0.0)
			#health -= 1
			#return damage / 2
		#else:
			#if randf() <= guard: # bite
				#mood = minf(mood + randf_range(cooperation * 0.5, cooperation + 0.1), 1.0)
				##guard = minf(guard + randf_range(cooperation / 2, cooperation + 0.1), 1.0)
				#return damage
		#return 0
	#
	#func treat():
		#mood = minf(mood + cooperation * 2, 1.0)
		#guard = maxf(guard - cooperation, 0.0)
		#satisfaction += cooperation * 2 * (1.0 + mood)
		#return 0
	#
	#func sticker():
		#return satisfaction >= SATISFACTION_MIN or pow(randf(), 2) >= 0.97

class Dog:
	extends Animal
	const TEXTURE = preload("res://graphics/animals/dog.png")
	func _init():
		super._init(TEXTURE, &"dog", 0.9, 0, 0.9, 10, 1, 0.3, 1)

class BadDog:
	extends Animal
	const TEXTURE = preload("res://graphics/animals/dog.png")
	func _init():
		super._init(TEXTURE, &"dog", 0.1, 0.9, 0.7, 10, 3, 0.7, 2)

class Giraffe:
	extends Animal
	const TEXTURE = preload("res://graphics/animals/giraffe.png")
	func _init():
		super._init(TEXTURE, &"giraffe", 0.0, 1.0, 0.1, 30, 5, 0.9, 5)

enum AnimalType {
	DOG,
	BAD_DOG,
	GIRAFFE,
}

var animals = {
	AnimalType.DOG: Dog,
	AnimalType.BAD_DOG: BadDog,
	AnimalType.GIRAFFE: Giraffe,
}
