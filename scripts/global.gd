extends Node

enum RPS {
	ROCK,
	PAPER,
	SCISSORS,
}
const DEFAULT_CA = 0.004
var player_name: String = "player"
var treats: int = 0
var animals: Array[Animals.Animal] = [Animals.Dog.new(), Animals.Dog.new(), Animals.BadDog.new(), Animals.BadDog.new(), Animals.Dog.new()]
