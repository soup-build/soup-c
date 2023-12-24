Name: "Soup.C"
Language: "Wren|0"
Version: "0.2.0"
Source: [
	"Tasks/BuildTask.wren"
	"Tasks/InitializeDefaultsTask.wren"
	"Tasks/RecipeBuildTask.wren"
	"Tasks/ResolveDependenciesTask.wren"
	"Tasks/ResolveToolsTask.wren"
]

Dependencies: {
	Runtime: [
		"mwasplund|Soup.C.Compiler@0"
		"mwasplund|Soup.C.Compiler.Clang@0"
		"mwasplund|Soup.C.Compiler.GCC@0"
		"mwasplund|Soup.C.Compiler.MSVC@0"
		"mwasplund|Soup.Build.Utils@0"
	]
	Tool: [
		"[C++]mwasplund|copy@1.0"
		"[C++]mwasplund|mkdir@1.0"
	]
}