extends Node

var debug_animals: Array[Animals.Animal] = [Animals.Dog.new(), Animals.BadDog.new(), Animals.Cat.new(), Animals.Pigeon.new(), Animals.BadDog.new(), Animals.Snake.new(), Animals.Turtle.new(), Animals.BadderDog.new(), Animals.Cat.new()]

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
var bonus_unlocked: bool
var bonus_visited: bool
var time: float
var animals: Array[Animals.Animal] = debug_animals if OS.is_debug_build() else []

var ca_enabled: bool = true
var timer_enabled: bool = false
var mouse_sens: float = 0.0005

func get_time_text():
	return "%d:%06.3f" % [floori(time / 60.0), time - floorf(time / 60.0) * 60.0]
