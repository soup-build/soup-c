Name: "Soup.C"
Language: "Wren|0.1"
Version: "0.1.0"
Source: [
	"Tasks/BuildTask.wren"
	"Tasks/InitializeDefaultsTask.wren"
	"Tasks/RecipeBuildTask.wren"
	"Tasks/ResolveDependenciesTask.wren"
	"Tasks/ResolveToolsTask.wren"
]

Dependencies: {
	Runtime: [
		"Soup.C.Compiler@0.1"
		"Soup.C.Compiler.Clang@0.1"
		"Soup.C.Compiler.GCC@0.1"
		"Soup.C.Compiler.MSVC@0.1"
		"Soup.Build.Utils@0.3"
	]
	Tool: [
		"C++|copy@1.0"
		"C++|mkdir@1.0"
	]
}