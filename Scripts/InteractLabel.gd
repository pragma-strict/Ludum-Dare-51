extends Label


func show_text(new_text:String):
	self.text = new_text
	self.visible = true
	
	
func hide_text():
	self.text = ""
	self.visible = false



func _on_Player_looked_at_item(item_interact_string:String):
	show_text(item_interact_string)


func _on_Player_looked_away_from_item():
	hide_text()
