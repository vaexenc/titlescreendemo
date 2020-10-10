local scene = {}

scene.scenes = {}
scene.currentSceneName = ""

function scene.addScene(sceneName, sceneTable)
	scene.scenes[sceneName] = sceneTable
end

function scene.getScene(sceneName)
	if scene.scenes[sceneName] then
		return scene.scenes[sceneName]
	end
end

function scene.getCurrentScene()
	return scene.getScene(scene.currentSceneName)
end

function scene.executeCurrentSceneFunction(functionName, ...)
	local currentScene = scene.getCurrentScene()
	if currentScene and currentScene[functionName] then
		currentScene[functionName](...)
	end
end

function scene.setScene(sceneName, passTable)
	scene.executeCurrentSceneFunction("exit")
	collectgarbage()
	scene.currentSceneName = sceneName
	scene.executeCurrentSceneFunction("load", passTable)
end

return scene