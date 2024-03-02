extends Node

class Animal:
	const PROGRESS_MIN = 0.9
	var texture: Texture2D
	var animal_name: StringName
	# 0 to 1
	var friendliness: float # friendliness is the willingness to be petted. small friendliness -> kick it -> friendliness up
	var original_friendliness: float # inital friendliness
	var cooperation: float # the boost given to progress when petted
	var damage: int # damage it deals to the player
	var progress: float # self explanatory. over 90% -> can be stickered
	
	func _init(_texture: Texture2D, _animal_name: StringName, _friendliness: float, _cooperation: float, _damage: int):
		randomize()
		texture = _texture
		animal_name = _animal_name
		friendliness = _friendliness
		original_friendliness = friendliness
		cooperation = _cooperation
		damage = _damage
		progress = 0
	
	func pet():
		if randf() <= friendliness:
			progress += cooperation
			return true
		return false
	
	func kick():
		if randf() > friendliness:
			#progress += cooperation
			friendliness = clampf(friendliness + cooperation / 3, 0, minf(original_friendliness + 0.2, 1.0))
			return true
		else:
			progress = maxf(progress - cooperation / 2, 0)
			friendliness = clampf(friendliness - 0.1, 0, minf(original_friendliness + 0.2, 1.0))
			return false
	
	func sticker():
		return progress >= PROGRESS_MIN or pow(randf(), 2) >= 0.97

class Dog:
	extends Animal
	func _init():
		super._init(preload("res://graphics/animals/dog.png"), &"dog", 0.9, 0.4, 1)

enum AnimalType {
	DOG,
}

var animals = {
	AnimalType.DOG: Dog,
}
