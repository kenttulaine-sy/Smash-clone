@tool
extends EditorScript

func _run():
	var scene = load("res://assets/2d_fortnite.glb")
	if scene == null:
		print("Failed to load scene")
		return
	
	var inst = scene.instantiate()
	print("Root: ", inst.name, " type: ", inst.get_class())
	
	inspect_node(inst, 0)

func inspect_node(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print(indent, node.name, " (", node.get_class(), ")")
	
	if node is AnimationPlayer:
		print(indent, "  Animations: ", node.get_animation_list())
	
	for child in node.get_children():
		inspect_node(child, depth + 1)
