Name: 'Soup.C'
Language: 'Wren|0'
Version: 0.5.0
Source: [
	'tasks/build-task.wren'
	'tasks/expand-source-task.wren'
	'tasks/initialize-defaults-task.wren'
	'tasks/recipe-build-task.wren'
	'tasks/resolve-dependencies-task.wren'
	'tasks/resolve-tools-task.wren'
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