extends Node

class Animal:
	var texture: Texture2D
	var animal_name: StringName
	# 0 to 1
	var friendliness: float
	var original_friendliness: float
	var cooperation: float
	var damage: int
	var progress: float
	
	func _init(_texture: Texture2D, _animal_name: StringName, _friendliness: float, _cooperation: float, _damage: int):
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
			progress += cooperation
			friendliness = clampf(friendliness + cooperation / 3, 0, original_friendliness + 0.2)
			return true
		else:
			progress = maxf(progress - cooperation / 2, 0)
			return false
	
	func sticker():
		return progress >= 0.9 or pow(randf(), 2) >= 0.97

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
