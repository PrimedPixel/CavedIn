extends Control

@onready var menu_canvas = $MenuCanvas
@onready var menu_container = $MenuCanvas/MenuContainer

@onready var end_screen_container = $MenuCanvas/EndScreenContainer
@onready var end_screen_label = $MenuCanvas/EndScreenContainer/Label

@onready var how_to_container = $MenuCanvas/HowToContainer
@onready var how_to_back_button = $MenuCanvas/HowToContainer/BackButton

@onready var start_button = $MenuCanvas/MenuContainer/StartButton
@onready var retry_button = $MenuCanvas/EndScreenContainer/RetryButton

@onready var world = $World


func _ready():
	get_tree().paused = true
	
	start_button.grab_focus()


func gameover(text: String):
	menu_canvas.visible = true
	menu_container.visible = false
	end_screen_container.visible = true
	
	end_screen_label.text = "You Died!\n\n" + text
	
	retry_button.grab_focus()
	
	get_tree().paused = true


func _on_start_button_pressed():
	get_tree().paused = false
	menu_canvas.visible = false
	
	world.start()

func _on_how_to_button_pressed():
	menu_container.visible = false
	how_to_container.visible = true
	
	how_to_back_button.grab_focus()


func _on_how_to_back_button_pressed():
	how_to_container.visible = false
	menu_container.visible = true
	
	start_button.grab_focus()
	

func _on_socials_button_pressed():
	OS.shell_open("https://primedpixel.co.uk/links/")


func _on_retry_button_pressed():
	world.start()
	
	menu_canvas.visible = false
	get_tree().paused = false


func _on_back_button_pressed():
	menu_container.visible = true
	end_screen_container.visible = false
	
	start_button.grab_focus()
