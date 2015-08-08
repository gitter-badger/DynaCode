DynaCode.2
==========

What is it?
-----------
DynaCode.2 is the second overhaul of DynaCode.1 which was never actually released, DynaCode.2 was originally going to be an update for the original, but because the new version completely changes the way the framework functions, it deserved its own version.

DynaCode is a powerful framework for creating stunning ComputerCraft Programs, it is used by all new HexCode (0) programs.

How do I use it?
----------------

DynaCode uses an XML format called (CCML - ComputerCraft Markup Language) to structure the layout (scene).
*CCML is like FXML (JavaFX)

It is modeled closely after JavaFX, by that it uses the following concepts:

###Scene
A scene is a layout, it contains all the nodes (items) that are to be visually displayed and all settings to be applied when the scene is applied (set)

###Stage
A stage is basically a window, when a new stage is created a new window (tab) will be created. This functionality is only just working and thus only one stage should be used at a time.

###Node
A node is an on-screen element, such as a button, text field or scroll area. It is to be added to a scene which is then drawn when the stage is.


To create a stage:

	window = DynaCode.stage.new()
	-- returns a new table containing methods to be used on the stage

To add scenes to a stage:

	mainScene = DynaCode.scene.create()
	window.setScene( mainScene )

To add nodes to a scene:

	mainScene.addAll({
		DynaCode.button(),
		DynaCode.input()
	})
	-- The window will reflect changes made to the scene on the next redraw (DynaCode.Buffer.draw())


What happens behind the scenes?
-------------------------------

When you create a stage, the API returns a table to you that contains the default methods. These methods allow you to Add, remove, edit and clean the stage.

This new stage needs to be stored in a variable because it is not stored anywhere in the API. With the new variable you created you can now start using it.

To begin using your new stage, you need to create a scene. A scene is basically a page or a layout, it contains all your Nodes. When you create a scene the API will return a table to you containing methods, these methods allow you to Add, Remove, Edit and Remove nodes set to it.

When you create a node the parent is set to false, this means that it will not exist to the API. Before it will respond to OS Events, it must be bound to a parent, to do this it must:
- be in a scene
- the scene must be in a stage

When you add a node to a scene, it sets the nodes parent to the scene itself, not a property or ID. This way other parts of the API can directly interface with the scene via a node attached to it. However, the node will still ignore OS Events, before it is "present" according to the API, the scene it is owned by must be in a scene.

When you set the scene of a stage, the scenes parent is set to a direct copy of the stage, much like the scene, it allows direct interfacing.