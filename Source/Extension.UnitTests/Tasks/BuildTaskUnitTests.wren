// <copyright file="BuildTaskUnitTests.wren" company="Soup">
// Copyright (c) Soup. All rights reserved.
// </copyright>

import "soup-test" for SoupTest, SoupTestOperation
import "../../Extension/Tasks/BuildTask" for BuildTask
import "../../Compiler/Core/BuildArguments" for BuildOptimizationLevel, BuildTargetType
import "../../Compiler/Core/LinkArguments" for LinkArguments, LinkTarget
import "../../Compiler/Core/MockCompiler" for MockCompiler
import "../../Compiler/Core/CompileArguments" for LanguageStandard, OptimizationLevel, SharedCompileArguments, TranslationUnitCompileArguments
import "mwasplund|Soup.Build.Utils:./Path" for Path
import "../../Test/Assert" for Assert

class BuildTaskUnitTests {
	construct new() {
	}

	RunTests() {
		System.print("BuildTaskUnitTests.Build_WindowsApplication")
		this.Build_WindowsApplication()
		System.print("BuildTaskUnitTests.Build_Executable")
		this.Build_Executable()
		System.print("BuildTaskUnitTests.Build_Library_MultipleFiles")
		this.Build_Library_MultipleFiles()
	}

	Build_WindowsApplication() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Program"
		buildTable["TargetType"] = BuildTargetType.WindowsApplication
		buildTable["LanguageStandard"] = LanguageStandard.C17
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			"TestFile.c",
		]

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Operation: ./TestFile.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.c")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.WindowsApplication
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile.mock.obj"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("bin/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile.c"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Executable() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Program"
		buildTable["TargetType"] = BuildTargetType.Executable
		buildTable["LanguageStandard"] = LanguageStandard.C17
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			"TestFile.c",
		]

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Operation: ./TestFile.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Program.exe",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")

		var expectedTranslationUnitArguments = TranslationUnitCompileArguments.new()
		expectedTranslationUnitArguments.SourceFile = Path.new("TestFile.c")
		expectedTranslationUnitArguments.TargetFile = Path.new("obj/TestFile.mock.obj")

		expectedCompileArguments.ImplementationUnits = [
			expectedTranslationUnitArguments,
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetType = LinkTarget.Executable
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetFile = Path.new("bin/Program.exe")
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile.mock.obj"),
		]

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./bin/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile.c"),
				],
				[
					Path.new("obj/TestFile.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}

	Build_Library_MultipleFiles() {
		// Setup the input build state
		SoupTest.initialize()
		var activeState = SoupTest.activeState
		var globalState = SoupTest.globalState

		// Setup build table
		var buildTable = {}
		activeState["Build"] = buildTable
		buildTable["Architecture"] = "x64"
		buildTable["Compiler"] = "MOCK"
		buildTable["TargetName"] = "Library"
		buildTable["TargetType"] = BuildTargetType.StaticLibrary
		buildTable["LanguageStandard"] = LanguageStandard.C17
		buildTable["SourceRootDirectory"] = "C:/source/"
		buildTable["TargetRootDirectory"] = "C:/target/"
		buildTable["ObjectDirectory"] = "obj/"
		buildTable["BinaryDirectory"] = "bin/"
		buildTable["Source"] = [
			"TestFile1.c",
			"TestFile2.c",
			"TestFile3.c",
		]
		buildTable["IncludeDirectories"] = [
			"Folder",
			"AnotherFolder/Sub",
		]
		buildTable["OptimizationLevel"] = BuildOptimizationLevel.None

		// Setup dependencies table
		var dependenciesTable = {}
		globalState["Dependencies"] = dependenciesTable
		dependenciesTable["Tool"] = {
			"mkdir": {
				"SharedState": {
					"Build": {
						"RunExecutable": "/TARGET/mkdir.exe"
					}
				}
			}
		}

		// Register the mock compiler
		var compiler = MockCompiler.new()
		BuildTask.registerCompiler("MOCK", Fn.new { |activeState| compiler })

		BuildTask.evaluate()

		// Verify expected logs
		Assert.ListEqual(
			[
				"INFO: Using Compiler: MOCK",
				"INFO: Generate Compile Operation: ./TestFile1.c",
				"INFO: Generate Compile Operation: ./TestFile2.c",
				"INFO: Generate Compile Operation: ./TestFile3.c",
				"INFO: CoreLink",
				"INFO: Linking target",
				"INFO: Generate Link Operation: ./bin/Library.mock.lib",
				"INFO: Build Generate Done",
			],
			SoupTest.logs)

		// Setup the shared arguments
		var expectedCompileArguments = SharedCompileArguments.new()
		expectedCompileArguments.Standard = LanguageStandard.C17
		expectedCompileArguments.Optimize = OptimizationLevel.None
		expectedCompileArguments.SourceRootDirectory = Path.new("C:/source/")
		expectedCompileArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedCompileArguments.ObjectDirectory = Path.new("obj/")
		expectedCompileArguments.IncludeDirectories = [
			Path.new("Folder"),
			Path.new("AnotherFolder/Sub"),
		]

		expectedCompileArguments.ImplementationUnits = [
			TranslationUnitCompileArguments.new(
				Path.new("TestFile1.c"),
				Path.new("obj/TestFile1.mock.obj")),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile2.c"),
				Path.new("obj/TestFile2.mock.obj")),
			TranslationUnitCompileArguments.new(
				Path.new("TestFile3.c"),
				Path.new("obj/TestFile3.mock.obj")),
		]

		var expectedLinkArguments = LinkArguments.new()
		expectedLinkArguments.TargetFile = Path.new("bin/Library.mock.lib")
		expectedLinkArguments.TargetType = LinkTarget.StaticLibrary
		expectedLinkArguments.TargetArchitecture = "x64"
		expectedLinkArguments.TargetRootDirectory = Path.new("C:/target/")
		expectedLinkArguments.ObjectFiles = [
			Path.new("obj/TestFile1.mock.obj"),
			Path.new("obj/TestFile2.mock.obj"),
			Path.new("obj/TestFile3.mock.obj"),
		]
		expectedLinkArguments.LibraryFiles = []

		// Verify expected compiler calls
		Assert.ListEqual(
			[
				expectedCompileArguments,
			],
			compiler.GetCompileRequests())
		Assert.ListEqual(
			[
				expectedLinkArguments,
			],
			compiler.GetLinkRequests())

		// Verify build state
		var expectedBuildOperations = [
			SoupTestOperation.new(
				"MakeDir [./obj/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./obj/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./obj/"),
				]),
			SoupTestOperation.new(
				"MakeDir [./bin/]",
				Path.new("/TARGET/mkdir.exe"),
				[
					"./bin/",
				],
				Path.new("C:/target/"),
				[],
				[
					Path.new("./bin/"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile1.c"),
				],
				[
					Path.new("obj/TestFile1.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile2.c"),
				],
				[
					Path.new("obj/TestFile2.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockCompile: 1",
				Path.new("MockCompiler.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("TestFile3.c"),
				],
				[
					Path.new("obj/TestFile3.mock.obj"),
				]),
			SoupTestOperation.new(
				"MockLink: 1",
				Path.new("MockLinker.exe"),
				[
					"Arguments",
				],
				Path.new("MockWorkingDirectory"),
				[
					Path.new("InputFile.in"),
				],
				[
					Path.new("OutputFile.out"),
				]),
		]

		Assert.ListEqual(
			expectedBuildOperations,
			SoupTest.operations)
	}
}
