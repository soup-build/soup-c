Name: 'Soup.C'
Language: 'Wren|0'
Version: '0.4.1'
Source: [
	'Tasks/BuildTask.wren'
	'Tasks/ExpandSourceTask.wren'
	'Tasks/InitializeDefaultsTask.wren'
	'Tasks/RecipeBuildTask.wren'
	'Tasks/ResolveDependenciesTask.wren'
	'Tasks/ResolveToolsTask.wren'
]

Dependencies: {
	Runtime: [
		'mwasplund|Soup.C.Compiler@0.4'
		'mwasplund|Soup.C.Compiler.Clang@0.4'
		'mwasplund|Soup.C.Compiler.GCC@0.4'
		'mwasplund|Soup.C.Compiler.MSVC@0.4'
		'mwasplund|Soup.Build.Utils@0'
	]
	Tool: [
		'[C++]mwasplund|copy@1.0'
		'[C++]mwasplund|mkdir@1.0'
	]
}