extends Node

var debug_animals: Array[Animals.Animal] = [Animals.Dog.new(), Animals.Dog.new(), Animals.BadDog.new(), Animals.BadDog.new(), Animals.Dog.new()]

signal treat_collected
enum RPS {
	ROCK,
	PAPER,
	SCISSORS,
}
const DEFAULT_CA = 0.004
var player_name: String = "player"
var treats: int = 0
var collected_treats: int = 0
var total_treats: int = 0
var animals: Array[Animals.Animal] = debug_animals if OS.is_debug_build() else []

var ca_enabled: bool = true
var timer_enabled: bool = false
